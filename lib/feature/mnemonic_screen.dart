import 'package:flutter/material.dart';
import 'package:wallet_test/feature/main_screen.dart';

class MnemonicScreen extends StatelessWidget {
  final String mnemonic;
  const MnemonicScreen({
    super.key,
    required this.mnemonic,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Mnemonic'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mnemonic,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _next(context),
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ),
      );

  void _next(BuildContext context) =>
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
}
