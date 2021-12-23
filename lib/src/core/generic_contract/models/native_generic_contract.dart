import 'dart:async';
import 'dart:ffi';

import '../../../ffi_utils.dart';
import '../../../models/nekoton_exception.dart';
import '../../../nekoton.dart';

class NativeGenericContract {
  Pointer<Void>? _ptr;

  NativeGenericContract(this._ptr);

  bool get isNull => _ptr == null;

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) async {
    if (_ptr == null) {
      throw GenericContractNotFoundException();
    } else {
      return function(_ptr!);
    }
  }

  Future<void> free() async {
    if (_ptr == null) {
      throw GenericContractNotFoundException();
    } else {
      final ptr = _ptr;
      _ptr = null;

      await proceedAsync(
        (port) => nativeLibraryInstance.bindings.free_generic_contract(
          port,
          ptr!,
        ),
      );
    }
  }
}
