import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rust_ffi.dart';

final rustCoreProvider = Provider<RustCore>((_) => RustCore.instance);

final coreVersionProvider = Provider<String>((ref) {
  return ref.watch(rustCoreProvider).version();
});

class HashController extends StateNotifier<String> {
  HashController(this._core) : super('');
  final RustCore _core;

  void compute(String input) {
    state = input.isEmpty ? '' : _core.sha256(input);
  }
}

final hashControllerProvider =
    StateNotifierProvider<HashController, String>((ref) {
  return HashController(ref.watch(rustCoreProvider));
});

class EmailController extends StateNotifier<bool?> {
  EmailController(this._core) : super(null);
  final RustCore _core;

  void check(String input) {
    state = input.isEmpty ? null : _core.validateEmail(input);
  }
}

final emailControllerProvider =
    StateNotifierProvider<EmailController, bool?>((ref) {
  return EmailController(ref.watch(rustCoreProvider));
});

class JsonController extends StateNotifier<String?> {
  JsonController(this._core) : super(null);
  final RustCore _core;

  void enrich(String input) {
    if (input.isEmpty) {
      state = null;
      return;
    }
    state = _core.enrichJson(input) ?? 'parse error';
  }
}

final jsonControllerProvider =
    StateNotifierProvider<JsonController, String?>((ref) {
  return JsonController(ref.watch(rustCoreProvider));
});
