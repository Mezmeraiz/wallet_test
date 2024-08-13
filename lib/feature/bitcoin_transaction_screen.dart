import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_test/di/dependency_scope.dart';
import 'package:wallet_test/domain/wallet_service.dart';

enum LoadingStatus {
  idle,
  loading,
}

class BitcoinTransactionScreen extends StatefulWidget {
  const BitcoinTransactionScreen({super.key});

  @override
  State<BitcoinTransactionScreen> createState() => _BitcoinTransactionScreenState();
}

class _BitcoinTransactionScreenState extends State<BitcoinTransactionScreen> {
  LoadingStatus status = LoadingStatus.idle;
  late final WalletService _walletService;
  String toAddress = '';
  String amount = '';

  @override
  void initState() {
    super.initState();
    _walletService = DependencyScope.of(context).walletService;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Send transaction'),
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
                    labelText: 'Enter address',
                  ),
                  onChanged: (value) {
                    toAddress = value;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter amount',
                  ),
                  onChanged: (value) {
                    amount = value;
                  },
                ),
                const SizedBox(height: 16),
                status == LoadingStatus.idle
                    ? ElevatedButton(
                        onPressed: _sendBitcoinTransaction,
                        child: const Text('Send'),
                      )
                    : const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );

  void _sendBitcoinTransaction() async {
    setState(() {
      status = LoadingStatus.loading;
    });

    late final String result;

    try {
      result = await _walletService.sendBitcoinTransaction(toAddress, amount);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    } finally {
      setState(() {
        status = LoadingStatus.idle;
      });
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Transaction result'),
          content: Text(result),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction hash copied to clipboard')),
                );
              },
              child: const Text('COPY'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
