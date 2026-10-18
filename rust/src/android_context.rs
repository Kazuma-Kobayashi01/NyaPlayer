//! Hands the Android application `Context` to `ndk-context`, which cpal's
//! AAudio backend needs to enumerate and open output devices. Without it the
//! first stream open panics ("android context was not initialized").
//!
//! Called once from Kotlin (`NyaCore.initAndroid`) before any playback.

use std::sync::Once;

use jni::errors::{Error, ThrowRuntimeExAndDefault};
use jni::objects::{JClass, JObject};
use jni::EnvUnowned;

static INIT: Once = Once::new();

#[no_mangle]
pub extern "system" fn Java_com_kazuma_nyaplayer_NyaCore_initAndroid<'caller>(
    mut env: EnvUnowned<'caller>,
    _class: JClass<'caller>,
    context: JObject<'caller>,
) {
    let outcome = env.with_env(|env| -> Result<(), Error> {
        let vm = env.get_java_vm()?;
        // The context must outlive every JNI frame, so the global reference
        // is intentionally leaked.
        let context = env.new_global_ref(context)?.into_raw();
        INIT.call_once(|| {
            // SAFETY: `vm` is the process's JavaVM and `context` a global
            // reference that is never deleted.
            unsafe { ndk_context::initialize_android_context(vm.get_raw().cast(), context.cast()) };
        });
        Ok(())
    });
    outcome.resolve::<ThrowRuntimeExAndDefault>()
}
