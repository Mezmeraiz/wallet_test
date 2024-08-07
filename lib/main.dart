import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Crypto Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum HomePageState {
  idle,
  error,
}

class _MyHomePageState extends State<MyHomePage> {
  late final Pointer<T> Function<T extends NativeType>(String symbolName) _lookup;

  late final Pointer<Utf8> Function(Pointer<Utf8>) _tWStringCreateWithUTF8Bytes;
  late final Pointer<Void> Function(int, Pointer<Utf8>) _tWHDWalletCreate;
  late final Pointer<Utf8> Function(Pointer<Void>) _tWHDWalletMnemonic;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _tWStringUTF8Bytes;
  late final Pointer<Utf8> Function(Pointer<Void>, int) _tWHDWalletGetAddressForCoin;

  String walletMnemonic = '';
  String bitcoinAddress = '';
  String error = '';
  HomePageState state = HomePageState.idle;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _generate() {
    var passPointer = _tWStringCreateWithUTF8Bytes(''.toNativeUtf8());

    final Pointer<Void> wallet = _tWHDWalletCreate(128, passPointer);

    final Pointer<Utf8> mnemonicPointer = _tWHDWalletMnemonic(wallet);
    final String mnemonic = _tWStringUTF8Bytes(mnemonicPointer).toDartString();

    final Pointer<Utf8> bitcoinAddressPointer = _tWHDWalletGetAddressForCoin(wallet, 0);
    final String bitcoin = _tWStringUTF8Bytes(bitcoinAddressPointer).toDartString();

    setState(() {
      walletMnemonic = mnemonic;
      bitcoinAddress = bitcoin;
      state = HomePageState.idle;
    });
  }

  void _init() {
    try {
      final dylib = DynamicLibrary.open('libTrustWalletCore.dylib');

      _lookup = dylib.lookup;

      _tWStringCreateWithUTF8Bytes =
          _lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>('TWStringCreateWithUTF8Bytes')
              .asFunction<Pointer<Utf8> Function(Pointer<Utf8>)>();

      _tWHDWalletCreate = _lookup<NativeFunction<Pointer<Void> Function(Int, Pointer<Utf8>)>>('TWHDWalletCreate')
          .asFunction<Pointer<Void> Function(int, Pointer<Utf8>)>();

      _tWHDWalletMnemonic = _lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>('TWHDWalletMnemonic')
          .asFunction<Pointer<Utf8> Function(Pointer<Void>)>();

      _tWStringUTF8Bytes = _lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>('TWStringUTF8Bytes')
          .asFunction<Pointer<Utf8> Function(Pointer<Utf8>)>();

      _tWHDWalletGetAddressForCoin =
          _lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>, Int32)>>('TWHDWalletGetAddressForCoin')
              .asFunction<Pointer<Utf8> Function(Pointer<Void>, int)>();
    } catch (e) {
      setState(() {
        state = HomePageState.error;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                state == HomePageState.error
                    ? error
                    : walletMnemonic.isNotEmpty
                        ? 'Wallet mnemonic\n$walletMnemonic\n\nBitcoin address\n$bitcoinAddress'
                        : '',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _generate,
                child: const Text(
                  'Generate wallet',
                ),
              ),
            ],
          ),
        ),
      );
}
