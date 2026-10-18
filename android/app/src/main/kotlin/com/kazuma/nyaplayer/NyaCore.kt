package com.kazuma.nyaplayer

import android.content.Context

/** JNI entry points of the Rust core (rust/src/android_context.rs). */
object NyaCore {
    init {
        System.loadLibrary("nya_core")
    }

    external fun initAndroid(context: Context)
}
