import 'package:wallet_test/data/model/coin.dart';
import 'package:wallet_test/data/model/coin_type.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

abstract class CoinUtils {
  static List<Coin> getCoins() => [
        const Coin(
          name: 'TRX',
          type: CoinType.coin,
          blockchain: 'Tron20',
          decimals: 6,
        ),
        const Coin(
          name: 'USDT',
          type: CoinType.token,
          blockchain: 'Tron20',
          contractAddress: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
          decimals: 6,
        ),
        const Coin(
          name: 'BTC',
          type: CoinType.coin,
          blockchain: 'Bitcoin',
          decimals: 8,
        ),
        const Coin(
          name: 'ETH',
          type: CoinType.coin,
          blockchain: 'Ethereum',
          decimals: 18,
        ),
        const Coin(
          name: 'BNB',
          type: CoinType.coin,
          blockchain: 'BNB Smart Chain (BEP20)',
          decimals: 18,
        ),
        const Coin(
          name: 'USDT',
          type: CoinType.token,
          blockchain: 'Ethereum',
          contractAddress: '0xdac17f958d2ee523a2206206994597c13d831ec7',
          decimals: 6,
        ),
        const Coin(
          name: 'USDT',
          type: CoinType.token,
          blockchain: 'BNB Smart Chain (BEP20)',
          contractAddress: '0x55d398326f99059ff775485246999027b3197955',
          decimals: 18,
        ),
        const Coin(
          name: 'SHIB',
          type: CoinType.token,
          blockchain: 'Ethereum',
          contractAddress: '0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce',
          decimals: 18,
        ),
      ];

  static TWCoinType getCoinTypeFromBlockchain(String blockchain) {
    // Маппинг между именами ключей и значениями TWCoinType
    final Map<String, TWCoinType> keyToEnumValue = {
      'Bitcoin': TWCoinType.TWCoinTypeBitcoin,
      'Ethereum': TWCoinType.TWCoinTypeEthereum,
      'BNB Smart Chain (BEP20)': TWCoinType.TWCoinTypeSmartChain,
      'Tron20': TWCoinType.TWCoinTypeTron,
    };

    // Возвращаем соответствующий enum, если ключ найден
    return keyToEnumValue[blockchain]!;
  }
}
