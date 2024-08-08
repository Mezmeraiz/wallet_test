import 'dart:ffi';

class LibraryStorage {
  Pointer<T> Function<T extends NativeType>(String symbolName) get lookup => _lookup;

  late final Pointer<T> Function<T extends NativeType>(String symbolName) _lookup;

  void init() {
    final dylib = DynamicLibrary.open('libTrustWalletCore.dylib');

    _lookup = dylib.lookup;
  }
}
