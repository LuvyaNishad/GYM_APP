package com.example.leon

import android.app.*
import android.content.*
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONObject

/** The persisted timer is authoritative for alarms/actions when Flutter is absent. */
object RestAlarm {
    private const val store = "workout_rest_v1"
    private const val alarmCode = 5101
    private const val countdownId = 1001
    private const val completionId = 1002
    var visible = false
    var changed: (() -> Unit)? = null

    private fun prefs(c: Context) = c.getSharedPreferences(store, Context.MODE_PRIVATE)
    @Synchronized fun read(c: Context): JSONObject? = prefs(c).getString("timer", null)?.let { JSONObject(it) }
    private fun write(c: Context, j: JSONObject) { check(prefs(c).edit().putString("timer", j.toString()).commit()) }
    fun exactAvailable(c: Context): Boolean = Build.VERSION.SDK_INT < 31 ||
        (c.getSystemService(Context.ALARM_SERVICE) as AlarmManager).canScheduleExactAlarms()

    private fun alarm(c: Context, j: JSONObject? = null) = PendingIntent.getBroadcast(c, alarmCode,
        Intent(c, RestAlarmReceiver::class.java).setAction("complete")
            .setData(Uri.parse("leon://rest/alarm"))
            .putExtra("timerId", j?.optString("timerId"))
            .putExtra("deadline", j?.optLong("deadline") ?: 0),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    @Synchronized fun schedule(c: Context, j: JSONObject) {
        require(j.getString("timerId").isNotBlank() && j.getString("workoutId").isNotBlank())
        require(j.getLong("deadline") > 0 && j.getInt("total") in 1..86400)
        j.put("phase", "running").put("delivered", false)
        write(c,j)
        arm(c,j)
        clear(c)
        if (!visible) showCountdown(c,j)
        if (!NotificationManagerCompat.from(c).areNotificationsEnabled()) {
            throw SecurityException("Enable notifications in Account to receive background rest alerts")
        }
    }

    private fun arm(c: Context, j: JSONObject) {
        val manager = c.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = alarm(c,j)
        manager.cancel(pi)
        val deadline = j.getLong("deadline").coerceAtLeast(System.currentTimeMillis()+100)
        if (exactAvailable(c)) manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,deadline,pi)
        else manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,deadline,pi)
    }

    @Synchronized fun cancel(c: Context, id: String? = null) {
        val current = read(c)
        if (id != null && current?.optString("timerId") != id) return
        (c.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(alarm(c))
        check(prefs(c).edit().remove("timer").commit())
        clear(c)
    }

    fun clear(c: Context) { NotificationManagerCompat.from(c).cancel(countdownId); NotificationManagerCompat.from(c).cancel(completionId) }
    @Synchronized fun visibility(c: Context, value: Boolean) {
        visible = value
        if (value) clear(c)
        else read(c)?.takeIf { it.optString("phase") == "running" && it.optLong("deadline") > System.currentTimeMillis() }
            ?.let { showCountdown(c,it) }
    }

    /** Claims foreground completion once; the receiver and Dart race safely. */
    @Synchronized fun complete(c: Context, id: String, background: Boolean): Boolean {
        if (background && visible) return false
        val j = read(c) ?: return false
        if (j.optString("timerId") != id || j.optBoolean("delivered") ||
            j.optString("phase") != "running" || j.optLong("deadline") > System.currentTimeMillis()+100) return false
        j.put("phase","completed").put("delivered",true)
        write(c,j)
        (c.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(alarm(c))
        NotificationManagerCompat.from(c).cancel(countdownId)
        if (background && !visible) showCompletion(c,j)
        changed?.invoke()
        return true
    }

    @Synchronized fun receive(c: Context, intent: Intent) {
        val j = read(c) ?: return
        if (intent.getStringExtra("timerId") != j.optString("timerId") ||
            intent.getLongExtra("deadline",0) != j.optLong("deadline") || j.optString("phase") != "running") return
        when (intent.action) {
            "complete" -> complete(c,j.getString("timerId"),true)
            "add_30" -> {
                if (j.getLong("deadline") <= System.currentTimeMillis()) return
                j.put("deadline",j.getLong("deadline")+30000)
                j.put("total",j.getInt("total")+30)
                write(c,j); arm(c,j); if (!visible) showCountdown(c,j); changed?.invoke()
            }
            "skip_rest" -> {cancel(c,j.getString("timerId"));changed?.invoke()}
        }
    }

    @Synchronized fun boot(c: Context) {
        val j = read(c) ?: return
        if (j.optString("phase") != "running") return
        if (j.optLong("deadline") <= System.currentTimeMillis()) {cancel(c);return}
        arm(c,j)
    }

    private fun open(c: Context) = PendingIntent.getActivity(c, 5100,
        Intent(c, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    private fun action(c: Context,j: JSONObject,action: String,code: Int) = PendingIntent.getBroadcast(c,code,
        Intent(c,RestAlarmReceiver::class.java).setAction(action)
            .setData(Uri.parse("leon://rest/${j.getString("timerId")}/${j.getLong("deadline")}/$action"))
            .putExtra("timerId",j.getString("timerId")).putExtra("deadline",j.getLong("deadline")),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    private fun channel(c: Context, sound: Boolean, vibrate: Boolean): String {
        val id = "leon_rest_v2_${sound}_${vibrate}"
        if (Build.VERSION.SDK_INT >= 26) {
            val ch = NotificationChannel(id, "Rest alerts (${if(sound) "sound" else "quiet"}${if(vibrate) ", vibrate" else ""})",NotificationManager.IMPORTANCE_HIGH)
            ch.enableVibration(vibrate)
            ch.vibrationPattern = longArrayOf(0,250,100,250)
            val uri = if (sound) Uri.parse("android.resource://${c.packageName}/${R.raw.complete}") else null
            ch.setSound(uri,android.media.AudioAttributes.Builder().setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION).build())
            (c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(ch)
        }
        return id
    }

    private fun showCountdown(c: Context,j: JSONObject) {
        if (Build.VERSION.SDK_INT >= 26) {
            (c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(
                NotificationChannel("leon_rest_status_v2","Rest timer",NotificationManager.IMPORTANCE_LOW).apply {setSound(null,null);enableVibration(false)})
        }
        val notification = NotificationCompat.Builder(c,"leon_rest_status_v2")
            .setSmallIcon(R.mipmap.ic_launcher).setContentTitle("Rest timer")
            .setContentText("Next: ${j.optString("exerciseName","Exercise")} · Set ${j.optInt("setNumber",1)}")
            .setWhen(j.getLong("deadline")).setUsesChronometer(true).setChronometerCountDown(true)
            .setOngoing(true).setOnlyAlertOnce(true).setSilent(true).setContentIntent(open(c))
            .addAction(0,"+30s",action(c,j,"add_30",5102))
            .addAction(0,"Skip Rest",action(c,j,"skip_rest",5103)).build()
        try {NotificationManagerCompat.from(c).notify(countdownId,notification)} catch(_:SecurityException) {}
    }

    private fun showCompletion(c: Context,j: JSONObject) {
        val sound = j.optBoolean("sound",true)
        val vibrate = j.optBoolean("vibrate",true)
        val builder = NotificationCompat.Builder(c,channel(c,sound,vibrate))
            .setSmallIcon(R.mipmap.ic_launcher).setContentTitle("Rest complete")
            .setContentText("Next: ${j.optString("exerciseName","Exercise")} · Set ${j.optInt("setNumber",1)}")
            .setPriority(NotificationCompat.PRIORITY_HIGH).setAutoCancel(true).setContentIntent(open(c))
        if (sound) builder.setSound(Uri.parse("android.resource://${c.packageName}/${R.raw.complete}"))
        if (vibrate) builder.setVibrate(longArrayOf(0,250,100,250))
        if (!sound && !vibrate) builder.setSilent(true)
        try {NotificationManagerCompat.from(c).notify(completionId,builder.build())} catch(_:SecurityException) {}
    }
}

class RestAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {RestAlarm.receive(context,intent)}
}
class RestBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {RestAlarm.boot(context)}
}
