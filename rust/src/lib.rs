//! Shared Rust core powering iOS, Android (and macOS/Windows/Chrome via the
//! same C-ABI surface). Cross-platform mobile clients call these symbols
//! through `dart:ffi` (Flutter) or JSI/TurboModule (React Native).
//!
//! Design rules:
//! - Public symbols are `extern "C"` and `#[no_mangle]`.
//! - Strings cross the boundary as null-terminated UTF-8 (`*const c_char`).
//! - Buffers we allocate are returned to callers, who MUST call
//!   `frc_string_free` to release them. Forgetting that leaks memory.
//! - Panics never cross FFI: every entry point catches unwinds and returns
//!   a sentinel value on failure.

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::panic::{catch_unwind, AssertUnwindSafe};

use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

fn cstr_to_str<'a>(ptr: *const c_char) -> Option<&'a str> {
    if ptr.is_null() {
        return None;
    }
    unsafe { CStr::from_ptr(ptr).to_str().ok() }
}

fn string_to_owned_cstr(s: String) -> *mut c_char {
    CString::new(s).map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut())
}

fn guard<F: FnOnce() -> *mut c_char>(f: F) -> *mut c_char {
    catch_unwind(AssertUnwindSafe(f)).unwrap_or(std::ptr::null_mut())
}

/// Return semantic version of the core. Caller must free with `frc_string_free`.
#[no_mangle]
pub extern "C" fn frc_version() -> *mut c_char {
    string_to_owned_cstr(env!("CARGO_PKG_VERSION").to_string())
}

/// SHA-256 of the input string, lowercase hex. Returns null on bad input.
#[no_mangle]
pub extern "C" fn frc_sha256(input: *const c_char) -> *mut c_char {
    guard(|| {
        let Some(s) = cstr_to_str(input) else {
            return std::ptr::null_mut();
        };
        let mut hasher = Sha256::new();
        hasher.update(s.as_bytes());
        string_to_owned_cstr(hex::encode(hasher.finalize()))
    })
}

/// RFC 5321-ish email validation. Returns "true" or "false" so the FFI
/// signature stays uniform across all entry points.
#[no_mangle]
pub extern "C" fn frc_validate_email(input: *const c_char) -> *mut c_char {
    guard(|| {
        let Some(s) = cstr_to_str(input) else {
            return string_to_owned_cstr("false".into());
        };
        string_to_owned_cstr(if is_valid_email(s) { "true".into() } else { "false".into() })
    })
}

/// Echo a JSON object with an added `processed_at_unix` field. Demonstrates
/// shared serde-driven parsing usable by both platforms.
#[no_mangle]
pub extern "C" fn frc_enrich_json(input: *const c_char) -> *mut c_char {
    guard(|| {
        let Some(s) = cstr_to_str(input) else {
            return std::ptr::null_mut();
        };
        match enrich_json_inner(s) {
            Ok(out) => string_to_owned_cstr(out),
            Err(_) => std::ptr::null_mut(),
        }
    })
}

/// Free a string previously returned by this library. Null pointer = no-op.
#[no_mangle]
pub extern "C" fn frc_string_free(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(ptr));
    }
}

fn is_valid_email(s: &str) -> bool {
    let s = s.trim();
    let Some((local, domain)) = s.split_once('@') else {
        return false;
    };
    if local.is_empty() || domain.is_empty() || domain.len() > 253 {
        return false;
    }
    if !domain.contains('.') {
        return false;
    }
    local
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || "._%+-".contains(c))
        && domain
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || ".-".contains(c))
}

#[derive(Debug, Serialize, Deserialize)]
struct Envelope {
    #[serde(flatten)]
    rest: serde_json::Map<String, serde_json::Value>,
}

static EPOCH: Lazy<std::time::SystemTime> = Lazy::new(|| std::time::UNIX_EPOCH);

fn enrich_json_inner(s: &str) -> Result<String, serde_json::Error> {
    let mut env: Envelope = serde_json::from_str(s)?;
    let now = std::time::SystemTime::now()
        .duration_since(*EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    env.rest.insert(
        "processed_at_unix".into(),
        serde_json::Value::Number(now.into()),
    );
    serde_json::to_string(&env)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sha256_known_vector() {
        let mut h = Sha256::new();
        h.update(b"abc");
        assert_eq!(
            hex::encode(h.finalize()),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        );
    }

    #[test]
    fn email_accepts_simple() {
        assert!(is_valid_email("a@b.co"));
        assert!(is_valid_email("foo.bar+x@example.com"));
    }

    #[test]
    fn email_rejects_bad() {
        assert!(!is_valid_email("noatsign"));
        assert!(!is_valid_email("@nolocal.com"));
        assert!(!is_valid_email("nodot@nodot"));
    }

    #[test]
    fn enrich_adds_field() {
        let out = enrich_json_inner(r#"{"a":1}"#).unwrap();
        assert!(out.contains("\"a\":1"));
        assert!(out.contains("processed_at_unix"));
    }
}
