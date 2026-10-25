package com.example.leon

import android.content.Context
import android.database.Cursor
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "LeonMainActivity"
        private const val PEDOMETER_CHANNEL = "com.example.leon/pedometer"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PEDOMETER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInbuiltSteps" -> {
                        try {
                            val data = queryInbuiltSteps()
                            result.success(data)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error querying inbuilt steps: ${e.message}", e)
                            result.success(null)
                        }
                    }
                    "getImmediateHardwareSteps" -> {
                        queryImmediateHardwareSteps(result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun queryInbuiltSteps(): Map<String, Any?>? {
        val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        Log.d(TAG, "queryInbuiltSteps searching for today: $todayStr")

        val hourly = MutableList(24) { 0 }
        var todayStepsSum = 0
        var foundTodayData = false
        val historyMap = mutableMapOf<String, Int>()

        // 1. Query day_statistic and day_statistic_v2 for daily aggregates & past records
        val statisticUris = listOf(
            "content://com.oplus.healthservice.stepprovider/day_statistic",
            "content://com.oplus.healthservice.stepprovider/day_statistic_v2"
        )
        for (uriStr in statisticUris) {
            var fbCursor: Cursor? = null
            try {
                val uri = Uri.parse(uriStr)
                fbCursor = contentResolver.query(uri, null, null, null, null)
                if (fbCursor != null && fbCursor.moveToFirst()) {
                    val colNames = fbCursor.columnNames
                    Log.d(TAG, "$uriStr columns: ${colNames.joinToString()}")
                    var dateIdx = -1
                    var stepIdx = -1
                    for (i in colNames.indices) {
                        val name = colNames[i].lowercase(Locale.getDefault())
                        if (name == "date" || name == "day_date" || name == "day" || name == "record_date") dateIdx = i
                        if (name == "step" || name == "amount" || name == "day_offset" || name == "total_step" || name == "day_step") {
                            stepIdx = i
                        }
                    }
                    if (stepIdx != -1) {
                        do {
                            val rawDate = if (dateIdx != -1) fbCursor.getString(dateIdx) else null
                            val steps = fbCursor.getInt(stepIdx)
                            if (rawDate != null && steps > 0) {
                                val normDate = if (rawDate.length >= 10) rawDate.substring(0, 10) else rawDate
                                if (normDate == todayStr) {
                                    if (steps > todayStepsSum) {
                                        todayStepsSum = steps
                                        foundTodayData = true
                                    }
                                } else {
                                    historyMap[normDate] = maxOf(historyMap[normDate] ?: 0, steps)
                                }
                            }
                        } while (fbCursor.moveToNext())
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Query $uriStr failed: ${e.message}")
            } finally {
                fbCursor?.close()
            }
        }

        // 2. Query minute-by-minute step_data directly from ColorOS / Realme StepProvider
        var cursor: Cursor? = null
        try {
            val uri = Uri.parse("content://com.oplus.healthservice.stepprovider/step_data")
            cursor = contentResolver.query(uri, null, null, null, null)
            if (cursor != null && cursor.moveToFirst()) {
                val colNames = cursor.columnNames
                Log.d(TAG, "step_data columns: ${colNames.joinToString()}")

                var timeIdx = -1
                var tsIdx = -1
                var stepIdx = -1

                for (i in colNames.indices) {
                    val name = colNames[i].lowercase(Locale.getDefault())
                    if (name == "minute_time") timeIdx = i
                    if (name == "minute_timestamp") tsIdx = i
                    if (name == "minute_offset" || name == "minute_step") {
                        if (stepIdx == -1 || name == "minute_offset") stepIdx = i
                    }
                }

                if (stepIdx != -1 && (timeIdx != -1 || tsIdx != -1)) {
                    val cal = Calendar.getInstance()
                    var minuteStepsTodaySum = 0
                    val minuteStepHistory = mutableMapOf<String, Int>()

                    do {
                        var rowDate: String? = null
                        var hour = -1

                        if (timeIdx != -1) {
                            val timeStr = cursor.getString(timeIdx)
                            if (timeStr != null && timeStr.length >= 10) {
                                rowDate = timeStr.substring(0, 10)
                                if (timeStr.length >= 13) {
                                    val delimiter = timeStr[10]
                                    if (delimiter == '-' || delimiter == ' ' || delimiter == 'T') {
                                        hour = timeStr.substring(11, 13).toIntOrNull() ?: -1
                                    }
                                }
                            }
                        }

                        if (rowDate == null && tsIdx != -1) {
                            val ts = cursor.getLong(tsIdx)
                            if (ts > 0) {
                                cal.timeInMillis = ts
                                rowDate = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(cal.time)
                                hour = cal.get(Calendar.HOUR_OF_DAY)
                            }
                        }

                        val steps = cursor.getInt(stepIdx)
                        if (rowDate != null && steps > 0) {
                            if (rowDate == todayStr) {
                                if (hour in 0..23) {
                                    hourly[hour] += steps
                                }
                                minuteStepsTodaySum += steps
                                foundTodayData = true
                            } else {
                                minuteStepHistory[rowDate] = (minuteStepHistory[rowDate] ?: 0) + steps
                            }
                        }
                    } while (cursor.moveToNext())

                    // Merge minuteStepHistory into historyMap
                    for ((d, s) in minuteStepHistory) {
                        historyMap[d] = maxOf(historyMap[d] ?: 0, s)
                    }

                    if (minuteStepsTodaySum > todayStepsSum) {
                        todayStepsSum = minuteStepsTodaySum
                    }
                    Log.d(TAG, "Extracted step_data today: sum=$todayStepsSum, hourly=$hourly, historyCount=${historyMap.size}")
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "query step_data failed: ${e.message}")
        } finally {
            cursor?.close()
        }

        // 3. Determine all-time record and date from history + today
        var recordSteps = todayStepsSum
        var recordDate = todayStr
        for ((d, s) in historyMap) {
            if (s > recordSteps) {
                recordSteps = s
                recordDate = d
            }
        }

        val formattedRecordDate: String
        val parts = recordDate.split("-")
        formattedRecordDate = if (parts.size == 3) "${parts[2]}/${parts[1]}/${parts[0]}" else recordDate

        if (foundTodayData || todayStepsSum > 0 || historyMap.isNotEmpty()) {
            return mapOf(
                "todaySteps" to todayStepsSum,
                "todayDate" to todayStr,
                "history" to historyMap,
                "hourlySteps" to hourly,
                "recordSteps" to recordSteps,
                "recordDate" to formattedRecordDate,
                "source" to "oplus_provider"
            )
        }

        Log.d(TAG, "No inbuilt step provider returned data")
        return null
    }

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
