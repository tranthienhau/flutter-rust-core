import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';

/// dart:ffi binding layer for `flutter_rust_core_ffi`.
///
/// The Rust crate is compiled to:
/// - iOS: a static lib statically linked into the app -> resolved via
///   `DynamicLibrary.process()`.
/// - Android: a `libflutter_rust_core_ffi.so` per ABI shipped via the
///   gradle build -> resolved via `DynamicLibrary.open(...)`.
class RustCore {
  RustCore._(this._lib) {
    _version =
        _lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
            'frc_version');
    _sha256 = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)>('frc_sha256');
    _validateEmail = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)>('frc_validate_email');
    _enrichJson = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)>('frc_enrich_json');
    _stringFree = _lib.lookupFunction<Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)>('frc_string_free');
  }

  static final RustCore instance = RustCore._(_open());

  final DynamicLibrary _lib;
  late final Pointer<Utf8> Function() _version;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _sha256;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _validateEmail;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _enrichJson;
  late final void Function(Pointer<Utf8>) _stringFree;

  static DynamicLibrary _open() {
    if (Platform.isIOS || Platform.isMacOS) {
      return DynamicLibrary.process();
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('libflutter_rust_core_ffi.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('flutter_rust_core_ffi.dll');
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  String version() => _consume(_version());

  String sha256(String input) {
    final ptr = input.toNativeUtf8();
    try {
      return _consume(_sha256(ptr));
    } finally {
      calloc.free(ptr);
    }
  }

  bool validateEmail(String input) {
    final ptr = input.toNativeUtf8();
    try {
      return _consume(_validateEmail(ptr)) == 'true';
    } finally {
      calloc.free(ptr);
    }
  }

  String? enrichJson(String input) {
    final ptr = input.toNativeUtf8();
    try {
      final out = _enrichJson(ptr);
      if (out == nullptr) return null;
      return _consume(out);
    } finally {
      calloc.free(ptr);
    }
  }

  /// Convert a Rust-owned C string to Dart and free the Rust allocation.
  /// Skipping the free here is the most common FFI memory leak in this kind
  /// of binding, so it lives in exactly one place.
  String _consume(Pointer<Utf8> ptr) {
    if (ptr == nullptr) return '';
    try {
      return ptr.toDartString();
    } finally {
      _stringFree(ptr);
    }
  }
}
