//! Power and lock state, read straight from the kernel / procfs.
//!
//! AC state comes from `/sys/class/power_supply`. Instead of polling it, we
//! subscribe to kernel uevents on a netlink socket (the same events udev
//! sees) and re-read sysfs whenever a power_supply event arrives. The caller
//! should still re-check occasionally as a safety net; see `Watcher::open`.

use std::fs;
use std::io;
use std::os::fd::{AsFd, AsRawFd, BorrowedFd, FromRawFd, OwnedFd};
use std::path::Path;

const POWER_SUPPLY_DIR: &str = "/sys/class/power_supply";

/// Whether the machine is running on mains power.
///
/// Mains adapters are authoritative: on AC if any is online. Without any
/// (a machine whose firmware only reports a battery), a discharging battery
/// means battery power. With neither, assume a desktop on AC.
pub fn on_ac() -> bool {
    on_ac_in(Path::new(POWER_SUPPLY_DIR))
}

fn read_trimmed(path: &Path) -> Option<String> {
    fs::read_to_string(path).ok().map(|s| s.trim().to_owned())
}

fn on_ac_in(root: &Path) -> bool {
    let Ok(entries) = fs::read_dir(root) else { return true };
    let (mut mains_seen, mut mains_online, mut discharging) = (false, false, false);
    for entry in entries.filter_map(|e| e.ok()) {
        let dir = entry.path();
        match read_trimmed(&dir.join("type")).as_deref() {
            Some("Mains") => {
                mains_seen = true;
                mains_online |= read_trimmed(&dir.join("online")).as_deref() == Some("1");
            }
            Some("Battery") => {
                discharging |= read_trimmed(&dir.join("status")).as_deref() == Some("Discharging");
            }
            _ => {}
        }
    }
    if mains_seen {
        mains_online
    } else {
        !discharging
    }
}

/// Whether hyprlock is running (the screen is locked, so nothing is visible).
pub fn screen_locked() -> bool {
    let Ok(entries) = fs::read_dir("/proc") else { return false };
    entries
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name().to_string_lossy().bytes().all(|b| b.is_ascii_digit()))
        .any(|e| read_trimmed(&e.path().join("comm")).as_deref() == Some("hyprlock"))
}

/// Listens for kernel uevents so power changes are noticed immediately.
pub struct Watcher {
    sock: Option<OwnedFd>,
}

impl Watcher {
    /// If the socket can't be opened, the watcher is inert and the caller's
    /// periodic re-check is the only source of updates.
    pub fn open() -> Self {
        let open = || -> io::Result<OwnedFd> {
            unsafe {
                let fd = libc::socket(
                    libc::AF_NETLINK,
                    libc::SOCK_DGRAM | libc::SOCK_NONBLOCK | libc::SOCK_CLOEXEC,
                    libc::NETLINK_KOBJECT_UEVENT,
                );
                if fd < 0 {
                    return Err(io::Error::last_os_error());
                }
                let fd = OwnedFd::from_raw_fd(fd);
                let mut addr: libc::sockaddr_nl = std::mem::zeroed();
                addr.nl_family = libc::AF_NETLINK as libc::sa_family_t;
                // Group 1: events broadcast by the kernel itself; readable without privileges.
                addr.nl_groups = 1;
                let len = std::mem::size_of::<libc::sockaddr_nl>() as libc::socklen_t;
                if libc::bind(fd.as_raw_fd(), &addr as *const _ as *const libc::sockaddr, len) < 0 {
                    return Err(io::Error::last_os_error());
                }
                Ok(fd)
            }
        };
        match open() {
            Ok(fd) => Watcher { sock: Some(fd) },
            Err(e) => {
                eprintln!("shades: cannot listen for power events ({e}); falling back to polling");
                Watcher { sock: None }
            }
        }
    }

    pub fn fd(&self) -> Option<BorrowedFd<'_>> {
        self.sock.as_ref().map(|s| s.as_fd())
    }

    /// Drains pending events; true if any of them concerned a power supply.
    pub fn drain(&self) -> bool {
        let Some(sock) = &self.sock else { return false };
        let mut buf = [0u8; 8192];
        let mut seen = false;
        loop {
            let n = unsafe { libc::recv(sock.as_raw_fd(), buf.as_mut_ptr().cast(), buf.len(), 0) };
            if n <= 0 {
                break;
            }
            seen |= is_power_supply_event(&buf[..n as usize]);
        }
        seen
    }
}

/// Uevents are NUL-separated `KEY=value` strings after an `action@path` header.
fn is_power_supply_event(msg: &[u8]) -> bool {
    msg.split(|&b| b == 0).any(|field| field == b"SUBSYSTEM=power_supply")
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fake_supply(root: &Path, name: &str, files: &[(&str, &str)]) {
        let dir = root.join(name);
        fs::create_dir_all(&dir).unwrap();
        for (file, content) in files {
            fs::write(dir.join(file), format!("{content}\n")).unwrap();
        }
    }

    fn tempdir(tag: &str) -> std::path::PathBuf {
        let d = std::env::temp_dir().join(format!("shades-test-{tag}-{}", std::process::id()));
        let _ = fs::remove_dir_all(&d);
        fs::create_dir_all(&d).unwrap();
        d
    }

    #[test]
    fn mains_online_is_ac() {
        let d = tempdir("online");
        fake_supply(&d, "AC", &[("type", "Mains"), ("online", "1")]);
        fake_supply(&d, "BAT0", &[("type", "Battery"), ("status", "Charging")]);
        assert!(on_ac_in(&d));
    }

    #[test]
    fn mains_offline_is_battery_even_with_usb_sources() {
        let d = tempdir("offline");
        fake_supply(&d, "AC", &[("type", "Mains"), ("online", "0")]);
        fake_supply(&d, "BAT0", &[("type", "Battery"), ("status", "Discharging")]);
        // Like the ucsi-source entries on the ThinkPad: these power peripherals.
        fake_supply(&d, "ucsi-source-psy-USBC000:001", &[("type", "USB"), ("online", "1")]);
        assert!(!on_ac_in(&d));
    }

    #[test]
    fn falls_back_to_battery_status_without_mains() {
        let d = tempdir("nomains");
        fake_supply(&d, "BAT0", &[("type", "Battery"), ("status", "Discharging")]);
        assert!(!on_ac_in(&d));
        fake_supply(&d, "BAT0", &[("type", "Battery"), ("status", "Full")]);
        assert!(on_ac_in(&d));
    }

    #[test]
    fn desktop_without_supplies_is_ac() {
        assert!(on_ac_in(&tempdir("empty")));
    }

    #[test]
    fn recognizes_power_supply_uevents() {
        let msg = b"change@/devices/LNXSYSTM:00/ACPI0003:00/power_supply/AC\0ACTION=change\0SUBSYSTEM=power_supply\0POWER_SUPPLY_ONLINE=0\0";
        assert!(is_power_supply_event(msg));
        assert!(!is_power_supply_event(b"add@/devices/x\0ACTION=add\0SUBSYSTEM=usb\0"));
    }
}
