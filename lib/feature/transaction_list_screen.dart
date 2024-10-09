import 'package:flutter/material.dart';
import 'package:wallet_test/common/utils/coin_utils.dart';
import 'package:wallet_test/common/utils/utils.dart';
import 'package:wallet_test/data/model/coin.dart';
import 'package:wallet_test/data/model/coin_type.dart';
import 'package:wallet_test/data/model/transaction_preview.dart';
import 'package:wallet_test/di/dependency_scope.dart';
import 'package:wallet_test/feature/coin_detail_screen.dart';
import 'package:wallet_test/feature/highlighted_text.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _searchController = TextEditingController();
  final _transactions = <TransactionPreview>[];

  @override
  void initState() {
    super.initState();
    var btcService = DependencyScope.of(context).serviceFactory.getService('Bitcoin');
    var ethService = DependencyScope.of(context).serviceFactory.getService('Ethereum');
    btcService.getTransactions();
    ethService.getTransactions();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Transactions'),
        ),
        body: Column(
          children: [
            Expanded(
              child: _transactions.isEmpty
                  ? const Center(
                      child: Text('No results'),
                    )
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return ListTile(
                          title: Text(
                            '${transaction.type.name} ${transaction.address}',
                            //subText: _searchController.text,
                          ),
                          subtitle: Text(
                            transaction.count.toString(),
                            //subText: _searchController.text,
                          ),
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => CoinDetailScreen(
                            //       coin: coin,
                            //     ),
                            //   ),
                            // );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }
}
