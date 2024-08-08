import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:wallet_test/data/library_storage.dart';
import 'package:wallet_test/data/model/coin_type.dart';

class WalletRepository {
  final Pointer<T> Function<T extends NativeType>(String symbolName) _lookup;

  WalletRepository({required LibraryStorage libraryStorage}) : _lookup = libraryStorage.lookup;

  late final Pointer<Void> _wallet;

  void walletCreate() {
    final tWHDWalletCreate = _lookup<NativeFunction<Pointer<Void> Function(Int, Pointer<Utf8>)>>('TWHDWalletCreate')
        .asFunction<Pointer<Void> Function(int, Pointer<Utf8>)>();

    var passPointer = pointerFromString('');

    _wallet = tWHDWalletCreate(128, passPointer);

    stringDelete(passPointer);
  }

  void walletCreateWithMnemonic(String mnemonic, {String passphrase = ""}) {
    if (!mnemonicIsValid(mnemonic)) throw Exception("mnemonic is invalid");
    final tWHDWalletCreateWithMnemonic =
        _lookup<NativeFunction<Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>)>>('TWHDWalletCreateWithMnemonic')
            .asFunction<Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>)>();

    final mnemonicPointer = pointerFromString(mnemonic);
    final passphrasePointer = pointerFromString(passphrase);

    _wallet = tWHDWalletCreateWithMnemonic(mnemonicPointer, passphrasePointer);

    stringDelete(mnemonicPointer);
    stringDelete(passphrasePointer);
  }

  Pointer<Utf8> pointerFromString(String string) {
    final tWStringCreateWithUTF8Bytes =
        _lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>('TWStringCreateWithUTF8Bytes')
            .asFunction<Pointer<Utf8> Function(Pointer<Utf8>)>();

    return tWStringCreateWithUTF8Bytes(string.toNativeUtf8());
  }

  String stringFromPointer(Pointer<Utf8> pointer) {
    final tWStringUTF8Bytes = _lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>('TWStringUTF8Bytes')
        .asFunction<Pointer<Utf8> Function(Pointer<Utf8>)>();

    return tWStringUTF8Bytes(pointer).toDartString();
  }

  String walletMnemonic() {
    final tWHDWalletMnemonic = _lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>('TWHDWalletMnemonic')
        .asFunction<Pointer<Utf8> Function(Pointer<Void>)>();

    final Pointer<Utf8> mnemonicPointer = tWHDWalletMnemonic(_wallet);

    return stringFromPointer(mnemonicPointer);
  }

  String walletGetAddressForCoin(TWCoinType coinType) {
    final tWHDWalletGetAddressForCoin =
        _lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>, Int32)>>('TWHDWalletGetAddressForCoin')
            .asFunction<Pointer<Utf8> Function(Pointer<Void>, int)>();

    final Pointer<Utf8> pointer = tWHDWalletGetAddressForCoin(_wallet, coinType.value);

    return stringFromPointer(pointer);
  }

  bool mnemonicIsValid(String mnemonic) {
    final tWMnemonicIsValid = _lookup<NativeFunction<Bool Function(Pointer<Utf8>)>>('TWMnemonicIsValid')
        .asFunction<bool Function(Pointer<Utf8>)>();

    return tWMnemonicIsValid(pointerFromString(mnemonic));
  }

  void stringDelete(Pointer<Utf8> pointer) {
    final tWStringDelete = _lookup<NativeFunction<Void Function(Pointer<Utf8>)>>('TWStringDelete')
        .asFunction<void Function(Pointer<Utf8>)>();

    tWStringDelete(pointer);
  }
}
