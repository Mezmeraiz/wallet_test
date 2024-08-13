import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:wallet_test/common/extension.dart';
import 'package:wallet_test/data/library_storage.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

class WalletRepository {
  final TrustWalletCore _core;

  WalletRepository({
    required LibraryStorage libraryStorage,
    required TrustWalletCore core,
  }) : _core = core;

  late final Pointer<TWHDWallet> _wallet;

  void walletCreate() {
    final Pointer<TWString1> passPointer = pointerFromString('');

    _wallet = _core.TWHDWalletCreate(128, passPointer);

    stringDelete(passPointer);
  }

  void walletCreateWithMnemonic(String mnemonic, {String passphrase = ''}) {
    if (!mnemonicIsValid(mnemonic)) throw Exception('mnemonic is invalid');

    final Pointer<TWString1> mnemonicPointer = pointerFromString(mnemonic);
    final Pointer<TWString1> passphrasePointer = pointerFromString(passphrase);

    _wallet = _core.TWHDWalletCreateWithMnemonic(mnemonicPointer, passphrasePointer);

    stringDelete(mnemonicPointer);
    stringDelete(passphrasePointer);
  }

  Pointer<TWString1> pointerFromString(String string) => _core.TWStringCreateWithUTF8Bytes(string.toNativeChar());

  int hashTypeForCoin(TWCoinType coin) => _core.TWBitcoinScriptHashTypeForCoin(coin);

  String stringFromPointer(Pointer<TWString1> pointer) => _core.TWStringUTF8Bytes(pointer).toDartString();

  String walletMnemonic() {
    final Pointer<TWString1> mnemonicPointer = _core.TWHDWalletMnemonic(_wallet);

    return stringFromPointer(mnemonicPointer);
  }

  String walletGetAddressForCoin(TWCoinType coinType) {
    final Pointer<TWString1> pointer = _core.TWHDWalletGetAddressForCoin(_wallet, coinType);

    return stringFromPointer(pointer);
  }

  bool mnemonicIsValid(String mnemonic) {
    final Pointer<TWString1> pointer = pointerFromString(mnemonic);

    return _core.TWMnemonicIsValid(pointer);
  }

  void stringDelete(Pointer<TWString1> pointer) {
    _core.TWStringDelete(pointer);
  }

  Uint8List getKeyForCoin(TWCoinType coinType) {
    final Pointer<TWPrivateKey> pointer = _core.TWHDWalletGetKeyForCoin(_wallet, coinType);
    final Pointer<Void> data = _core.TWPrivateKeyData(pointer);

    return _core.TWDataBytes(data).asTypedList(_core.TWDataSize(data));
  }

  Uint8List signerPlan(Uint8List bytes, TWCoinType coin) {
    final Pointer<TWData> data = _core.TWDataCreateWithBytes(bytes.toPointerUint8(), bytes.length);
    final Pointer<TWData1> signer = _core.TWAnySignerPlan(data, coin);
    _core.TWDataDelete(data);

    return _core.TWDataBytes(signer).asTypedList(_core.TWDataSize(signer));
  }

  Uint8List sign(Uint8List bytes, TWCoinType coin) {
    final data = _core.TWDataCreateWithBytes(bytes.toPointerUint8(), bytes.length);
    final signer = _core.TWAnySignerSign(data, coin);
    _core.TWDataDelete(data);

    return _core.TWDataBytes(signer).asTypedList(_core.TWDataSize(signer));
  }

  Uint8List lockScriptForAddress(String string, TWCoinType coin) {
    final address = _core.TWStringCreateWithUTF8Bytes(string.toNativeUtf8().cast());

    final script = _core.TWBitcoinScriptLockScriptForAddress(address, coin);
    _core.TWStringDelete(address);
    final data = _core.TWBitcoinScriptData(script);

    return _core.TWDataBytes(script.cast()).asTypedList(_core.TWDataSize(data));
  }
}
