package com.example.smashdeck

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.KeyEvent
import android.os.Handler
import android.os.Looper
import android.media.AudioManager
import android.media.ToneGenerator

class MainActivity : FlutterActivity() {
    private lateinit var scoringChannel: MethodChannel
    private var volumeScoring = false
    private var downHeld = false
    private var longHandled = false
    private val handler = Handler(Looper.getMainLooper())
    private val undoPress = Runnable {
        if (volumeScoring && downHeld) {
            longHandled = true
            scoringChannel.invokeMethod("scoreKey", "undo")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        scoringChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smashdeck/umpire")
        scoringChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableVolumeScoring" -> {
                    volumeScoring = call.arguments == true
                    if (!volumeScoring) { handler.removeCallbacks(undoPress); downHeld = false }
                    result.success(null)
                }
                "chime" -> {
                    try {
                        val tone = ToneGenerator(AudioManager.STREAM_MUSIC, 35)
                        tone.startTone(ToneGenerator.TONE_PROP_BEEP2, 180)
                        handler.postDelayed({ tone.release() }, 400)
                        result.success(null)
                    } catch (e: Exception) { result.error("AUDIO_UNAVAILABLE", "Unable to play chime", null) }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        if (!volumeScoring) return super.onKeyDown(keyCode, event)
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            if (event.repeatCount == 0) scoringChannel.invokeMethod("scoreKey", "server")
            return true
        }
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            if (event.repeatCount == 0) {
                downHeld = true; longHandled = false
                handler.postDelayed(undoPress, 600)
            }
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean {
        if (!volumeScoring) return super.onKeyUp(keyCode, event)
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) return true
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            handler.removeCallbacks(undoPress)
            if (downHeld && !longHandled && !event.isCanceled) scoringChannel.invokeMethod("scoreKey", "receiver")
            downHeld = false
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    override fun onPause() {
        volumeScoring = false
        downHeld = false
        handler.removeCallbacks(undoPress)
        super.onPause()
    }
}
