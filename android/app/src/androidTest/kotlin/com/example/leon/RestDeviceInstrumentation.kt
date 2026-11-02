package com.example.leon

import android.app.Instrumentation
import android.content.Intent
import android.os.Bundle
import org.json.JSONObject

/** Runs native alarm checks without creating workouts or changing a schedule. */
class RestDeviceInstrumentation : Instrumentation() {
    private var arguments = Bundle()
    override fun onCreate(args: Bundle?) {
        super.onCreate(args); arguments = args ?: Bundle(); start()
    }
    override fun onStart() {
        val output = Bundle()
        try {
            val context = targetContext
            check(RestAlarm.read(context) == null) { "An existing rest timer must finish first" }
            val deadline = System.currentTimeMillis() + 25000
            val timer = JSONObject().put("timerId", "native-device-check")
                .put("workoutId", "native-device-check").put("deadline", deadline)
                .put("total", 25).put("exerciseName", "Rest alert check")
                .put("setNumber", 1).put("sound", false).put("vibrate", false)
            RestAlarm.visible = false
            RestAlarm.schedule(context, timer)
            if (arguments.getString("check") == "actions") {
                val add = Intent("add_30").putExtra("timerId", "native-device-check").putExtra("deadline", deadline)
                RestAlarm.receive(context, add)
                check(RestAlarm.read(context)!!.getLong("deadline") == deadline + 30000)
                RestAlarm.receive(context, add) // The old deadline is now stale.
                check(RestAlarm.read(context)!!.getLong("deadline") == deadline + 30000)
                RestAlarm.receive(context, Intent("skip_rest").putExtra("timerId", "native-device-check")
                    .putExtra("deadline", deadline + 30000))
                check(RestAlarm.read(context) == null)
                output.putString("result", "add30, stale-action rejection and skip passed")
            } else {
                output.putString("result", "Future native alarm scheduled; verify completion after process termination")
                output.putLong("deadline", deadline)
            }
            finish(android.app.Activity.RESULT_OK, output)
        } catch(error: Exception) {
            output.putString("failure", error.toString()); finish(android.app.Activity.RESULT_CANCELED, output)
        }
    }
}
