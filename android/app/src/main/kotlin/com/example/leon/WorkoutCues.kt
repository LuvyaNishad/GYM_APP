package com.example.leon

import android.content.*
import android.app.NotificationManager
import android.media.*
import android.os.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Brief cues use transient ducking, honour focus loss, and stop on route loss. */
class WorkoutCues(private val context: Context, private val interrupted: () -> Unit) {
    private val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val handler = Handler(Looper.getMainLooper())
    private val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
    private val pool = SoundPool.Builder().setMaxStreams(4).setAudioAttributes(attributes).build()
    private val sounds = mutableMapOf<String,Int>()
    private val loaded = mutableSetOf<Int>()
    private var pending: Pair<String,Long>? = null
    private val releaseFocus = Runnable { abandonFocus() }
    private val focus = AudioManager.OnAudioFocusChangeListener { change ->
        if (change < 0) {stop();interrupted()}
    }
    private val request = if (Build.VERSION.SDK_INT >= 26)
        AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            .setAudioAttributes(attributes).setOnAudioFocusChangeListener(focus).build() else null
    private val noisy = object: BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) {stop();interrupted()}
    }
    init {
        pool.setOnLoadCompleteListener { _, id, status ->
            if (status == 0) {
                loaded.add(id)
                pending?.takeIf { sounds[it.first] == id && System.currentTimeMillis()-it.second < 300 }
                    ?.let { playSound(it.first) }
            }
        }
        for (name in listOf("countdown","complete","metronome","bell")) {
            context.assets.openFd("flutter_assets/assets/audio/$name.wav").use { sounds[name] = pool.load(it,1) }
        }
        if (Build.VERSION.SDK_INT >= 33) context.registerReceiver(noisy,IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY),Context.RECEIVER_NOT_EXPORTED)
        else context.registerReceiver(noisy,IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY))
    }
    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> {
                // Foreground workout cues also respect the phone's DND mode.
                val notifications = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (notifications.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL) {
                    result.success(null); return
                }
                val cue = call.argument<String>("cue") ?: "metronome"
                if (call.argument<Boolean>("sound") == true) playSound(cue)
                if (call.argument<Boolean>("vibrate") == true) {
                    val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                    val duration = if (cue == "complete" || cue == "bell") 150L else 25L
                    if (Build.VERSION.SDK_INT >= 26) vibrator.vibrate(VibrationEffect.createOneShot(duration,VibrationEffect.DEFAULT_AMPLITUDE))
                    else vibrator.vibrate(duration)
                }
                result.success(null)
            }
            "stop" -> {stop();result.success(null)}
            else -> result.notImplemented()
        }
    }
    private fun playSound(name: String) {
        val id = sounds[name] ?: return
        if (!loaded.contains(id)) {pending = name to System.currentTimeMillis();return}
        val granted = if (Build.VERSION.SDK_INT >= 26) manager.requestAudioFocus(request!!)
            else manager.requestAudioFocus(focus,AudioManager.STREAM_MUSIC,AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        if (granted != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) return
        pending = null
        pool.play(id, .65f, .65f,1,0,1f)
        handler.removeCallbacks(releaseFocus)
        handler.postDelayed(releaseFocus,if (name == "complete") 1000 else 700)
    }
    private fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= 26) manager.abandonAudioFocusRequest(request!!)
        else manager.abandonAudioFocus(focus)
    }
    fun stop() {pending=null;pool.autoPause();handler.removeCallbacks(releaseFocus);abandonFocus()}
    fun close() {stop();pool.release();context.unregisterReceiver(noisy)}
}
