package com.example.leon

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val healthReader = HealthReader(this)
    private lateinit var exportFiles: ExportFiles
    private var cues: WorkoutCues? = null
    private val stepReader = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    companion object {
        private const val TAG = "LeonMainActivity"
        private const val PEDOMETER_CHANNEL = "com.example.leon/pedometer"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "leon/health")
            .setMethodCallHandler(healthReader::handle)
        exportFiles = ExportFiles(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "leon/files")
            .setMethodCallHandler(exportFiles::handle)
        val restChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "leon/rest")
        RestAlarm.changed = {mainHandler.post {restChannel.invokeMethod("changed",null)}}
        restChannel.setMethodCallHandler { call, result ->
            try {
                when(call.method) {
                    "schedule" -> {RestAlarm.schedule(this,org.json.JSONObject(call.arguments as Map<*,*>));result.success(null)}
                    "read" -> result.success(RestAlarm.read(this)?.let { j -> j.keys().asSequence().associateWith {j.get(it)} })
                    "visible" -> {RestAlarm.visibility(this,call.arguments == true);result.success(null)}
                    "complete" -> result.success(RestAlarm.complete(this,call.argument<String>("timerId")!!,call.argument<Boolean>("background") == true))
                    "cancel" -> {RestAlarm.cancel(this,call.arguments as? String);result.success(null)}
                    "exactAvailable" -> result.success(RestAlarm.exactAvailable(this))
                    "requestExact" -> {
                        if (android.os.Build.VERSION.SDK_INT >= 31 && !RestAlarm.exactAvailable(this)) {
                            startActivity(android.content.Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                                Uri.parse("package:$packageName")))
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch(e:Exception) {result.error("rest_error",e.message,null)}
        }
        val cueChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"leon/cues")
        cues = WorkoutCues(this) {mainHandler.post {cueChannel.invokeMethod("interrupted",null)}}
        cueChannel.setMethodCallHandler {call,result -> cues?.handle(call,result)}

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PEDOMETER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDailySteps" -> stepReader.execute {
                        try {
                            val snapshot = readDailySteps()
                            mainHandler.post { result.success(snapshot) }
                        } catch (e: SecurityException) {
                            mainHandler.post { result.error("permission_denied", e.message, null) }
                        } catch (e: Exception) {
                            Log.w(TAG, "Could not read daily steps", e)
                            mainHandler.post { result.error("step_sync_failed", e.message, null) }
                        }
                    }
                    "getInbuiltSteps" -> {
                        result.notImplemented()
                    }
                    "getImmediateHardwareSteps" -> {
                        queryImmediateHardwareSteps(result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        if (::exportFiles.isInitialized && exportFiles.onResult(requestCode, resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    // Shelf reads this same exported provider. day_step is a cumulative sensor
    // value; day_offset (or amount in the v2 view) is the actual daily total.
    // Read only daily rows, never minute data. Query off the Flutter UI thread.
    private fun readDailySteps(): Map<String, Any>? {
        val authority = "com.oplus.healthservice.stepprovider"
        if (packageManager.resolveContentProvider(authority, 0) == null) return null
        val tables = listOf(
            Triple("day_statistic_v2", "date", "amount"),
            Triple("day_statistic", "day_date", "day_offset")
        )
        for ((table, dateColumn, countColumn) in tables) {
            try {
                val days = sortedMapOf<String, Int>()
                contentResolver.query(
                    Uri.parse("content://$authority/$table"),
                    arrayOf(dateColumn, countColumn), null, null, "$dateColumn ASC"
                ).use { cursor ->
                    checkNotNull(cursor) { "Daily step provider returned no cursor" }
                    val dateIndex = cursor.getColumnIndexOrThrow(dateColumn)
                    val countIndex = cursor.getColumnIndexOrThrow(countColumn)
                    while (cursor.moveToNext()) {
                        val date = cursor.getString(dateIndex) ?: continue
                        val steps = cursor.getLong(countIndex)
                        if (date.matches(Regex("\\d{4}-\\d{2}-\\d{2}")) && steps in 0..Int.MAX_VALUE.toLong()) {
                            days[date] = steps.toInt()
                        }
                    }
                }
                val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
                days.keys.filter { it > today }.forEach { days.remove(it) }
                days.putIfAbsent(today, 0)
                Log.d(TAG, "Daily step sync: ${days.size} days, today=${days[today]}")
                return mapOf("date" to today, "days" to days, "source" to "Realme phone tracker")
            } catch (e: IllegalArgumentException) {
                if (table == tables.last().first) throw e
            }
        }
        return null
    }

    override fun onDestroy() {
        healthReader.close()
        RestAlarm.changed = null
        RestAlarm.visibility(this,false)
        cues?.close()
        stepReader.shutdown()
        super.onDestroy()
    }

    override fun onResume() {super.onResume();RestAlarm.visibility(this,true)}
    override fun onPause() {RestAlarm.visibility(this,false);cues?.stop();super.onPause()}

    private fun queryImmediateHardwareSteps(result: MethodChannel.Result) {
        val sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        val sensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (sensorManager == null || sensor == null) {
            Log.w(TAG, "TYPE_STEP_COUNTER sensor unavailable on device")
            result.success(null)
            return
        }

        val handler = Handler(Looper.getMainLooper())
        var responded = false

        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (!responded) {
                    responded = true
                    val rawSteps = event.values[0].toInt()
                    Log.d(TAG, "Immediate hardware step reading received: $rawSteps")
                    sensorManager.unregisterListener(this)
                    result.success(rawSteps)
                }
            }

            override fun onAccuracyChanged(s: Sensor?, accuracy: Int) {}
        }

        sensorManager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_FASTEST)
        sensorManager.flush(listener)

        // Timeout fallback after 400ms if device doesn't flush immediately
        handler.postDelayed({
            if (!responded) {
                responded = true
                sensorManager.unregisterListener(listener)
                Log.d(TAG, "Immediate hardware step reading timed out after 400ms")
                result.success(null)
            }
        }, 400)
    }
}
