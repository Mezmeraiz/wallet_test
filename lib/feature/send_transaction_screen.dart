import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_test/common/abstractions/base_blockchain_wallet.dart';
import 'package:wallet_test/common/utils/coin_utils.dart';
import 'package:wallet_test/data/model/coin.dart';
import 'package:wallet_test/di/dependency_scope.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

enum LoadingStatus {
  idle,
  loading,
}

class SendTransactionScreen extends StatefulWidget {
  final Coin coin;
  final TWCoinType coinType;

  SendTransactionScreen({
    super.key,
    required this.coin,
  }) : coinType = CoinUtils.getCoinTypeFromBlockchain(coin.blockchain);

  @override
  State<SendTransactionScreen> createState() => _SendTransactionScreenState();
}

class _SendTransactionScreenState extends State<SendTransactionScreen> {
  LoadingStatus status = LoadingStatus.idle;
  String amount = '1';
  late final IBlockchainWallet _blockchainWallet;
  late final Map<String, String> _wallets;
  final _addressController = TextEditingController();

  TWCoinType get _coinType => widget.coinType;

  @override
  void initState() {
    super.initState();

    _wallets = switch (_coinType) {
      TWCoinType.TWCoinTypeBitcoin => {
          'Толя': 'bc1q8st5wrn60v25lr9jpa7t7h058y5x4w44ffqjhp',
          'Олег': 'bc1qff4tp6dn3sgq0kfedyg509qedlc8j9d33prmtv',
        },
      TWCoinType.TWCoinTypeEthereum => {
          'Толя': '0xB76b77AeA6f5bBe1685E0F13020Dc6cE8c7C4C6F',
          'Олег': '0xE0b77680f7423f60023259e9A42a180BDEb49BC6',
        },
      TWCoinType.TWCoinTypeSmartChain => {
          'Макс': '0x100807F60D0BA07BAdEC3F3cAEF204086Da0dd65',
        },
      TWCoinType.TWCoinTypeTron => {
          'Макс': 'TQhrwC2MnqppuaJHgngj6oqae26nC4e4Qt',
        },
      _ => throw UnimplementedError(),
    };

    _blockchainWallet = DependencyScope.of(context).serviceFactory.getService(widget.coin.blockchain);
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
                Wrap(
                  spacing: 16,
                  children: _wallets.entries
                      .map(
                        (e) => ActionChip(
                          label: Text(e.key),
                          onPressed: () {
                            _addressController.text = e.value;
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter address',
                  ),
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
    final toAddress = _addressController.text;
    if (toAddress.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    setState(() {
      status = LoadingStatus.loading;
    });

    late final String result;

    try {
      result = await _blockchainWallet.sendTransaction(
        coin: widget.coin,
        toAddress: toAddress,
        amount: amount,
      );
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

  @override
  void dispose() {
    _addressController.dispose();

    super.dispose();
  }
}
