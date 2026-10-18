//! Routes `log` records and panics to logcat on Android (no extra crate:
//! liblog is part of the platform).

use std::ffi::{c_char, c_int, CString};

extern "C" {
    fn __android_log_write(prio: c_int, tag: *const c_char, text: *const c_char) -> c_int;
}

const TAG: &str = "nya_core";

fn write(prio: c_int, text: &str) {
    if let (Ok(tag), Ok(text)) = (CString::new(TAG), CString::new(text.replace('\0', " "))) {
        // SAFETY: both pointers are valid NUL-terminated strings for the call.
        unsafe { __android_log_write(prio, tag.as_ptr(), text.as_ptr()) };
    }
}

struct Logger;

impl log::Log for Logger {
    fn enabled(&self, metadata: &log::Metadata) -> bool {
        metadata.level() <= log::Level::Info
    }

    fn log(&self, record: &log::Record) {
        if !self.enabled(record.metadata()) {
            return;
        }
        let prio = match record.level() {
            log::Level::Error => 6,
            log::Level::Warn => 5,
            _ => 4,
        };
        write(prio, &format!("{}: {}", record.target(), record.args()));
    }

    fn flush(&self) {}
}

pub fn init() {
    if log::set_logger(&Logger).is_ok() {
        log::set_max_level(log::LevelFilter::Info);
    }
    let previous = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        write(6, &format!("panic: {info}"));
        previous(info);
    }));
}
