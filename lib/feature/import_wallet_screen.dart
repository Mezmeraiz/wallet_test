import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/di/dependency_scope.dart';
import 'package:wallet_test/feature/main_screen.dart';
import 'package:wallet_test/feature/mnemonic_screen.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  //var mnemonic = 'source myth gloom bless ring sunny spawn verify join park dolphin dash';
  var mnemonic = 'dawn cycle able climb unique final donate measure excess panic ten taste';
  late final WalletRepository _walletRepository;

  @override
  void initState() {
    super.initState();
    _walletRepository = DependencyScope.of(context).walletRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _importWallet();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Import Wallet'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter your mnemonic',
                  ),
                  onChanged: (value) {
                    mnemonic = value;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _importWallet,
                  child: const Text('Import Wallet'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _createNewWallet,
                  child: const Text('Create new wallet'),
                ),
              ],
            ),
          ),
        ),
      );

  void _importWallet() {
    _walletRepository.walletCreateWithMnemonic(mnemonic);

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  void _createNewWallet() {
    _walletRepository.walletCreate();
    final mnemonic = _walletRepository.walletMnemonic();
    Clipboard.setData(ClipboardData(text: mnemonic));

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MnemonicScreen(mnemonic: mnemonic)));
  }
}
