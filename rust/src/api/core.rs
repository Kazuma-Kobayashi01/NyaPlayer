/// Version of the Rust core, shown in the about page and used as a
/// smoke test that the bridge is loaded.
#[flutter_rust_bridge::frb(sync)]
pub fn core_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    #[cfg(target_os = "android")]
    crate::android_log::init();
    flutter_rust_bridge::setup_default_user_utils();
}
