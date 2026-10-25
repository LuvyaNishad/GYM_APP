package com.example.leon

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
                        // Return empty clean tracking dataset - all tracking starts fresh when user starts
                        result.success(
                            mapOf(
                                "todaySteps" to 0,
                                "hourlySteps" to List(24) { 0 },
                                "history" to emptyMap<String, Int>(),
                                "recordSteps" to 0,
                                "recordDate" to "--"
                            )
                        )
                    }
                    "getImmediateHardwareSteps" -> {
                        queryImmediateHardwareSteps(result)
                    }
                    else -> result.notImplemented()
                }
            }
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
