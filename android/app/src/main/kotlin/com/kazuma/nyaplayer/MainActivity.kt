package com.kazuma.nyaplayer

import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The Rust audio backend needs the Context before the first playback.
        NyaCore.initAndroid(applicationContext)
        // Playback on Android runs on Media3 (TECH_SPEC §4.7); Rust still reads tags.
        AndroidPlayerEngine.attach(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        // The Android version decides which storage permission applies
        // (see AndroidMusicPermission in Dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nyaplayer/platform")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                    else -> result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // The player keeps playing in the background; only the channels go.
        AndroidPlayerEngine.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
