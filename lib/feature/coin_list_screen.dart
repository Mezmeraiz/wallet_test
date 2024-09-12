import 'package:flutter/material.dart';
import 'package:wallet_test/common/utils/coin_utils.dart';
import 'package:wallet_test/common/utils/utils.dart';
import 'package:wallet_test/data/model/coin.dart';
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
  late final List<Coin> coins;
  //final _tokens = <MapEntry<String, String>>[];

  @override
  void initState() {
    super.initState();

    _loadTokens();
  }

  void _loadTokens() async {
    // String jsonString = await rootBundle.loadString(AssetJson.tokens);
    // var tokensMap = json.decode(jsonString) as Map<String, dynamic>;
    //
    // var usdtMap = Map<String, String>.from(tokensMap['USDT'] as Map);
    // //var g = tokensMap['USDT'];
    // _tokens.addAll(usdtMap.entries);

    coins = CoinUtils.getCoins();
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
              child: coins.isEmpty
                  ? const Center(
                      child: Text('No results'),
                    )
                  : ListView.builder(
                      itemCount: coins.length,
                      itemBuilder: (context, index) {
                        final coin = coins[index];
                        return ListTile(
                          title: HighlightedText(
                            coin.name,
                            subText: _searchController.text,
                          ),
                          subtitle: HighlightedText(
                            coin.blockchain,
                            subText: _searchController.text,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CoinDetailScreen(
                                  coin: coin,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            // Expanded(
            //   child: _coins.isEmpty
            //       ? const Center(
            //           child: Text('No results'),
            //         )
            //       : ListView.builder(
            //           itemCount: _coins.length,
            //           itemBuilder: (context, index) {
            //             final coinType = _coins[index];
            //             return ListTile(
            //               title: HighlightedText(
            //                 Utils.getCoinName(coinType),
            //                 subText: _searchController.text,
            //               ),
            //               subtitle: HighlightedText(
            //                 Utils.getCoinTicker(coinType),
            //                 subText: _searchController.text,
            //               ),
            //               onTap: () {
            //                 Navigator.push(
            //                   context,
            //                   MaterialPageRoute(
            //                     builder: (context) => CoinDetailScreen(coinType: coinType),
            //                   ),
            //                 );
            //               },
            //             );
            //           },
            //         ),
            // ),
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
