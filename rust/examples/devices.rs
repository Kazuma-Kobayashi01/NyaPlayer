//! Lists output devices and their default configs (diagnostics).
use rodio::cpal::traits::{DeviceTrait, HostTrait};

fn main() {
    let host = rodio::cpal::default_host();
    println!("host: {:?}", host.id());
    match host.default_output_device() {
        Some(d) => {
            println!("default: {:?}", d.description().map(|x| x.to_string()));
            println!("  default config: {:?}", d.default_output_config());
        }
        None => println!("no default output device"),
    }
    if let Ok(devs) = host.output_devices() {
        for d in devs {
            println!(
                "- {:?}: {:?}",
                d.description().map(|x| x.to_string()),
                d.default_output_config()
            );
        }
    }
    match rodio::DeviceSinkBuilder::open_default_sink() {
        Ok(_) => println!("open_default_sink: ok"),
        Err(e) => println!("open_default_sink: {e:?}"),
    }
}
