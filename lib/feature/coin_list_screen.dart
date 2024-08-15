import 'package:flutter/material.dart';
import 'package:wallet_test/common/utils.dart';
import 'package:wallet_test/feature/coin_detail_screen.dart';
import 'package:wallet_test/feature/highlighted_text.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

class CoinListScreen extends StatefulWidget {
  const CoinListScreen({super.key});

  @override
  State<CoinListScreen> createState() => _CoinListScreenState();
}

class _CoinListScreenState extends State<CoinListScreen> {
  final _searchController = TextEditingController();
  final _coins = <TWCoinType>[];

  @override
  void initState() {
    super.initState();

    _coins.addAll(TWCoinType.values);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Crypto Currencies'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onEditingComplete: _onSearch,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Search',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _onSearch,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _coins.isEmpty
                  ? const Center(
                      child: Text('No results'),
                    )
                  : ListView.builder(
                      itemCount: _coins.length,
                      itemBuilder: (context, index) {
                        final coinType = _coins[index];
                        return ListTile(
                          title: HighlightedText(
                            Utils.getCoinName(coinType),
                            subText: _searchController.text,
                          ),
                          subtitle: HighlightedText(
                            Utils.getCoinTicker(coinType),
                            subText: _searchController.text,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CoinDetailScreen(coinType: coinType),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      );

  void _onSearch() {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _coins.clear();

      final query = _searchController.text.toLowerCase();
      print(query);

      for (final coin in TWCoinType.values) {
        if (Utils.getCoinName(coin).toLowerCase().contains(query) ||
            Utils.getCoinTicker(coin).toLowerCase().contains(query)) {
          _coins.add(coin);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }
}
