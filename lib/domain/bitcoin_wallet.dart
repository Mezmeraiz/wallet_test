import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:http_interceptor/http/intercepted_http.dart';
import 'package:wallet_test/common/abstractions/base_blockchain_wallet.dart';
import 'package:wallet_test/common/utils/coin_utils.dart';
import 'package:wallet_test/common/utils/utils.dart';
import 'package:wallet_test/data/model/bitcoin_address_info.dart';
import 'package:wallet_test/data/model/coin.dart';
import 'package:wallet_test/data/model/result.dart';
import 'package:wallet_test/data/model/utxo.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';
import 'package:wallet_test/protobuf/Bitcoin.pb.dart' as bitcoin;

final class BitcoinWallet extends BaseBlockchainWallet {
  final InterceptedHttp _http;
  final WalletRepository _walletRepository;

  const BitcoinWallet({
    required InterceptedHttp http,
    required super.walletRepository,
  })  : _http = http,
        _walletRepository = walletRepository;

  @override
  Future<double> getBalance({
    required Coin coin,
  }) async {
    final addressBtc = getAddress(CoinUtils.getCoinTypeFromBlockchain(coin.blockchain));

    String url = 'https://rpc.ankr.com/http/btc_blockbook/api/v2/address/$addressBtc';

    final response = await _http.get(
      Uri.parse(url),
    );

    final result = BitcoinAddressInfo.fromJson(jsonDecode(response.body));

    final balance = result.balance;
    if (balance == null) {
      return 0.0;
    }

    final balanceBtc = double.parse(balance) / BigInt.from(10).pow(coin.decimals).toDouble();

    return balanceBtc;
  }

  @override
  Future<String> sendTransaction({
    required Coin coin,
    required String toAddress,
    required String amount,
  }) async {
    final amountInSatoshi = Utils.valueToMinUnit(double.parse(amount), coin.decimals).toString();

    TWCoinType coinType = TWCoinType.TWCoinTypeBitcoin;

    final addressBtc = getAddress(TWCoinType.TWCoinTypeBitcoin);
    final changeAddress = addressBtc;
    final secretPrivateKeyBtc = _walletRepository.getKeyForCoin(TWCoinType.TWCoinTypeBitcoin).toList();

    List<Utxo> selectedUtxos = await _loadUtxos(addressBtc, amountInSatoshi);

    final Iterable<bitcoin.UnspentTransaction> unspentTransactions = selectedUtxos
        .map((utxo) => bitcoin.UnspentTransaction(
              amount: $fixnum.Int64(int.parse(utxo.value)),
              outPoint: bitcoin.OutPoint(
                hash: hex.decode(utxo.txid).reversed.toList(),
                index: utxo.vout,
                sequence: 0xffffffff,
              ),
              script: _walletRepository.lockScriptForAddress(addressBtc, coinType),
            ))
        .toList();

    final signingInput = bitcoin.SigningInput(
      amount: $fixnum.Int64.parseInt(amountInSatoshi),
      hashType: _walletRepository.hashTypeForCoin(coinType),
      toAddress: toAddress,
      changeAddress: changeAddress,
      byteFee: $fixnum.Int64.parseInt('10'),
      coinType: coinType.value,
      utxo: unspentTransactions,
      privateKey: [
        secretPrivateKeyBtc,
      ],
    );

    final transactionPlan = bitcoin.TransactionPlan.fromBuffer(
      _walletRepository.signerPlan(signingInput.writeToBuffer(), coinType).toList(),
    );
    signingInput.plan = transactionPlan;
    signingInput.amount = transactionPlan.amount;
    final sign = _walletRepository.sign(signingInput.writeToBuffer(), coinType);
    final signingOutput = bitcoin.SigningOutput.fromBuffer(sign);
    final rawTx = Utils.bytesToHex(signingOutput.encoded);

    return _sendRawTransaction(rawTx);
  }

  Future<List<Utxo>> _loadUtxos(String addressBtc, String amount) async {
    String url = 'https://rpc.ankr.com/http/btc_blockbook/api/v2/utxo/$addressBtc';

    final responseUtxos = await _http.get(
      Uri.parse(url),
      params: {
        'confirmed': 'true',
      },
    );

    List<Utxo> selectedUtxos = [];

    if (responseUtxos.statusCode == 200) {
      final data = jsonDecode(responseUtxos.body) as List;
      final List<Utxo> utxos = data.map((e) => Utxo.fromJson(e)).toList();

      // Примерная стоимость одного байта в сатоши
      const int byteFee = 10; // Может варьироваться в зависимости от нагрузки на сеть

      // Расчет примерного размера транзакции
      int estimatedTxSize = (selectedUtxos.length * 148) + (2 * 34) + 10; // 2 - это 1 выход на получателя и 1 на сдачу

      // Инициализация estimatedFee
      int estimatedFee = estimatedTxSize * byteFee;

      int totalAmount = 0;

      for (final Utxo utxo in utxos) {
        if (totalAmount >= (int.parse(amount) + estimatedFee)) {
          break;
        }
        selectedUtxos.add(utxo);
        totalAmount += int.parse(utxo.value);
      }
    } else {
      throw Exception('Failed to load utxos ${responseUtxos.reasonPhrase}');
    }

    return selectedUtxos;
  }

  Future<String> _sendRawTransaction(String rawTx) async {
    String url = 'https://rpc.ankr.com/http/btc_blockbook/api/v2/sendtx/$rawTx';

    final response = await _http.get(
      Uri.parse(url),
    );

    return Result.fromJson(jsonDecode(response.body)).result;
  }
}
