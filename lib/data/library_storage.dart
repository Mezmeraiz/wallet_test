import 'dart:ffi';

class LibraryStorage {
  DynamicLibrary get library => _library;

  Pointer<T> Function<T extends NativeType>(String symbolName) get lookup => _library.lookup;

  late final DynamicLibrary _library;

  void init() {
    _library = DynamicLibrary.open('libTrustWalletCore.dylib');
  }
}
