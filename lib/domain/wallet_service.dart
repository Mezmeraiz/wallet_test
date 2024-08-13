import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:http_interceptor/http/intercepted_http.dart';
import 'package:wallet_test/common/utils.dart';
import 'package:wallet_test/data/model/result.dart';
import 'package:wallet_test/data/model/utxo.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';
import 'package:wallet_test/protobuf/Bitcoin.pb.dart' as Bitcoin;

class WalletService {
  final WalletRepository _walletRepository;
  final InterceptedHttp _http;

  WalletService({
    required WalletRepository walletRepository,
    required InterceptedHttp http,
  })  : _http = http,
        _walletRepository = walletRepository;

  Future<String> sendBitcoinTransaction(
    String toAddress,
    String amountBtc,
  ) async {
    final amount = Utils.btcToSatoshi(amountBtc);

    TWCoinType coin = TWCoinType.TWCoinTypeBitcoin;

    final addressBtc = _walletRepository.walletGetAddressForCoin(TWCoinType.TWCoinTypeBitcoin);
    final changeAddress = addressBtc;
    final secretPrivateKeyBtc = _walletRepository.getKeyForCoin(TWCoinType.TWCoinTypeBitcoin).toList();

    List<Utxo> selectedUtxos = await _loadUtxos(addressBtc, amount);

    final Iterable<Bitcoin.UnspentTransaction> unspentTransactions = selectedUtxos
        .map((utxo) => Bitcoin.UnspentTransaction(
              amount: $fixnum.Int64(int.parse(utxo.value)),
              outPoint: Bitcoin.OutPoint(
                hash: hex.decode(utxo.txid).reversed.toList(),
                index: utxo.vout,
                sequence: 0xffffffff,
              ),
              script: _walletRepository.lockScriptForAddress(addressBtc, coin),
            ))
        .toList();

    final signingInput = Bitcoin.SigningInput(
      amount: $fixnum.Int64.parseInt(amount),
      hashType: _walletRepository.hashTypeForCoin(coin),
      toAddress: toAddress,
      changeAddress: changeAddress,
      byteFee: $fixnum.Int64.parseInt('10'),
      coinType: coin.value,
      utxo: unspentTransactions,
      privateKey: [
        secretPrivateKeyBtc,
      ],
    );

    final transactionPlan = Bitcoin.TransactionPlan.fromBuffer(
      _walletRepository.signerPlan(signingInput.writeToBuffer(), coin).toList(),
    );
    signingInput.plan = transactionPlan;
    signingInput.amount = transactionPlan.amount;
    final sign = _walletRepository.sign(signingInput.writeToBuffer(), coin);
    final signingOutput = Bitcoin.SigningOutput.fromBuffer(sign);
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
