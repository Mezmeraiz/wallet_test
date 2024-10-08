import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:http_interceptor/http/intercepted_http.dart';
import 'package:wallet_test/common/abstractions/base_blockchain_wallet.dart';
import 'package:wallet_test/common/utils/coin_utils.dart';
import 'package:wallet_test/common/utils/utils.dart';
import 'package:wallet_test/data/model/coin.dart';
import 'package:wallet_test/data/model/coin_type.dart';
import 'package:wallet_test/data/model/result.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';
import 'package:wallet_test/protobuf/Ethereum.pb.dart' as ethereum;
import 'package:web3dart/crypto.dart';

//const String _testUrl = 'https://rpc.ankr.com/eth';
//const String _testUrl = 'https://rpc.ankr.com/eth_holesky';
const String _testUrl = 'https://eth.llamarpc.com';

final class EthereumWallet extends BaseBlockchainWallet {
  final InterceptedHttp _http;
  final WalletRepository _walletRepository;

  EthereumWallet({
    required InterceptedHttp http,
    required super.walletRepository,
  })  : _http = http,
        _walletRepository = walletRepository;

  @override
  Future<void> loadCoinInfo(List<Coin> coin) async {
    final address = getAddress(CoinUtils.getCoinTypeFromBlockchain('Ethereum'));

    final payload = [
      _getCoinBalancePayload(address),
      _getTokenBalancePayload(address, '0xdac17f958d2ee523a2206206994597c13d831ec7'),
      _getTokenDecimalPayload(address, '0xdac17f958d2ee523a2206206994597c13d831ec7'),
      _getTokenBalancePayload(address, '0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce'),
      _getTokenDecimalPayload(address, '0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce'),
    ];

    final response = await _http.post(
      Uri.parse(_testUrl),
      headers: {
        HttpHeaders.contentTypeHeader: ContentType.json.toString(),
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      // Парсим результат ответа
      final List<dynamic> responseData = jsonDecode(response.body);

      var f = responseData.cast<Map<String, dynamic>>().map((e) => _parseBigInt(Result.fromJson(e).result)).toList();
      print(f);
    } else {
      throw Exception('Failed to load transactions: ${response.reasonPhrase}');
    }
  }

  Map<String, Object> _getCoinBalancePayload(String address) => {
        'jsonrpc': '2.0',
        'method': 'eth_getBalance',
        'params': [address, 'latest'],
        'id': 1,
      };

  Map<String, Object> _ethCall(
    String contractAddress,
    String data,
  ) {
    final param = {
      'to': contractAddress, // Адрес контракта USDT
      'data': data,
    };

    final payload = {
      'jsonrpc': '2.0',
      'method': 'eth_call',
      'params': [
        param,
        'latest',
      ],
    };

    return payload;
  }

  Map<String, Object> _getTokenBalancePayload(
    String coinAddress,
    String contractAddress,
  ) {
    final methodHex = hex.encode(keccakUtf8('balanceOf(address)')).substring(0, 8);
    final data = '0x${methodHex}000000000000000000000000${coinAddress.substring(2)}';

    return _ethCall(
      contractAddress,
      data,
    );
  }

  Map<String, Object> _getTokenDecimalPayload(
    String coinAddress,
    String contractAddress,
  ) {
    final methodHex = hex.encode(keccakUtf8('decimals()')).substring(0, 8);
    final data = '0x$methodHex';

    return _ethCall(
      contractAddress,
      data,
    );
  }

  @override
  Future<void> getTransactions() async {
    final addressEth = getAddress(CoinUtils.getCoinTypeFromBlockchain('Ethereum'));

    const String url =
        'https://rpc.ankr.com/multichain/21fd90cf03434b65e8c3d165e00193674368c97f925167da8502b59cac084a74';

    final payload = {
      'jsonrpc': '2.0',
      'method': 'ankr_getTransactionsByAddress',
      'params': {'address': addressEth, 'fromBlock': '0x0', 'toBlock': 'latest', 'sort': 'desc'},
      'id': 1,
    };

    final payloadToken = {
      'jsonrpc': '2.0',
      'method': 'ankr_getTokenTransfers',
      'params': {'address': addressEth, 'fromBlock': '0x0', 'toBlock': 'latest', 'sort': 'desc'},
      'id': 1,
    };

    try {
      // Отправляем POST запрос на Ankr API
      final response = await _http.post(
        Uri.parse(url),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode(payload),
      );

      final responseToken = await _http.post(
        Uri.parse(url),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode(payloadToken),
      );

      if (response.statusCode == 200) {
        // Парсим результат ответа
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('Transactions: ${responseData['result']}');
      } else {
        throw Exception('Failed to load transactions: ${response.reasonPhrase}');
      }

      if (responseToken.statusCode == 200) {
        // Парсим результат ответа
        final Map<String, dynamic> responseData = jsonDecode(responseToken.body);
        print('Transactions: ${responseData['result']}');
      } else {
        throw Exception('Failed to load transactions: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Future<String> sendTransaction({
    required Coin coin,
    required String toAddress,
    required String amount,
  }) =>
      switch (coin.type) {
        CoinType.coin => _sendTransaction(
            coin,
            toAddress,
            amount,
          ),
        CoinType.token => _sendTokenTransaction(
            coin,
            toAddress,
            amount,
          ),
      };

  @override
  Future<double> getBalance({
    required Coin coin,
  }) =>
      switch (coin.type) {
        CoinType.coin => _getCoinBalance(coin),
        CoinType.token => _getTokenBalance(coin),
      };

  Future<double> _getCoinBalance(
    Coin coin,
  ) async {
    final addressEth = getAddress(CoinUtils.getCoinTypeFromBlockchain(coin.blockchain));

    final payload = {
      'jsonrpc': '2.0',
      'method': 'eth_getBalance',
      'params': [addressEth, 'latest'],
      // TODO: get response ID
      'id': 1,
    };

    try {
      final response = await _http.post(
        Uri.parse(_testUrl),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = Result.fromJson(jsonDecode(response.body)).result;

        final balance = BigInt.parse(result.substring(2), radix: 16);

        final balanceEth = balance / BigInt.from(10).pow(coin.decimals);

        return balanceEth;
      } else {
        throw Exception('Failed to load balance ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  BigInt _parseBigInt(String value) => BigInt.parse(value.substring(2), radix: 16);

  Future<double> _getTokenBalance(Coin coin) async {
    final coinType = CoinUtils.getCoinTypeFromBlockchain(coin.blockchain);
    final contractAddress = coin.contractAddress;
    final coinAddress = _walletRepository.walletGetAddressForCoin(coinType);

    final Uint8List list = keccakUtf8('balanceOf(address)');
    final hexString = hex.encode(list);
    final methodHex = hexString.substring(0, 8);
    final data = '0x${methodHex}000000000000000000000000${coinAddress.substring(2)}';

    final param = {
      'to': contractAddress, // Адрес контракта USDT
      'data': data,
    };

    final payload = {
      'jsonrpc': '2.0',
      'method': 'eth_call',
      'params': [
        param,
        'latest',
      ],
      // TODO: get response ID
      'id': 1,
    };

    try {
      final response = await _http.post(
        Uri.parse(_testUrl),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        var g = response.body;
        var result = Result.fromJson(jsonDecode(response.body)).result;

        // Убираем "0x" из начала строки
        result = result.replaceFirst('0x', '');

        result = result.isEmpty ? '0' : result;

        // Преобразуем hex-значение в десятичное
        BigInt balance = BigInt.parse(result, radix: 16);

        final tokenBalance = balance / BigInt.from(10).pow(coin.decimals);

        return tokenBalance;
      } else {
        throw Exception('Failed to load balance ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _sendTransaction(
    Coin coin,
    String toAddress,
    String amount,
  ) async {
    final amountInWei = Utils.valueToMinUnit(double.parse(amount), coin.decimals);
    final addressEth = getAddress(TWCoinType.TWCoinTypeEthereum);
    final privateKeyEth = _walletRepository.getKeyForCoin(TWCoinType.TWCoinTypeEthereum).toList();

    try {
      // Receive nonce
      final nonceResponse = await _http.post(
        Uri.parse(_testUrl),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionCount',
          'params': [addressEth, 'latest'],
          // TODO: get response ID
          'id': 1,
        }),
      );

      if (nonceResponse.statusCode == 200) {
        final nonceResult = Result.fromJson(jsonDecode(nonceResponse.body)).result;

        final nonce = _bigIntToUint8List(BigInt.parse(nonceResult.substring(2), radix: 16));

        // Returns the current price per gas in wei.
        final gasPriceResponse = await _http.post(
          Uri.parse(_testUrl),
          headers: {
            HttpHeaders.contentTypeHeader: ContentType.json.toString(),
          },
          body: jsonEncode({
            'jsonrpc': '2.0',
            'method': 'eth_gasPrice',
            'params': [],
            'id': 1,
          }),
        );

        if (gasPriceResponse.statusCode == 200) {
          final gasPriceResult = Result.fromJson(jsonDecode(gasPriceResponse.body)).result;
          final gasPrice = _bigIntToUint8List(BigInt.parse(gasPriceResult));
          final gasLimit = _intToUint8List(21000);

          final transaction = ethereum.Transaction(
            transfer: ethereum.Transaction_Transfer(
              amount: _bigIntToUint8List(amountInWei),
            ),
          );

          final chainId = _bigIntToUint8List(BigInt.parse('0x4268')); // TestNet

          final signedTransaction = ethereum.SigningInput(
            chainId: chainId,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            toAddress: toAddress,
            transaction: transaction,
            privateKey: privateKeyEth,
            nonce: nonce,
          );

          TWCoinType coin = TWCoinType.TWCoinTypeEthereum;
          final sign = _walletRepository.sign(signedTransaction.writeToBuffer(), coin);
          final signingOutput = ethereum.SigningOutput.fromBuffer(sign);
          final rawTx = Utils.bytesToHex(signingOutput.encoded);

          return _sendRawTransaction(rawTx, true);
        } else {
          throw Exception('Failed to send transaction ${gasPriceResponse.reasonPhrase}');
        }
      } else {
        throw Exception('Failed to send transaction ${nonceResponse.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _sendTokenTransaction(
    Coin coin,
    String toAddress,
    String amount,
  ) async {
    final amountInMinUnits = BigInt.from(double.parse(amount) * BigInt.from(10).pow(coin.decimals).toInt());
    final coinType = CoinUtils.getCoinTypeFromBlockchain(coin.blockchain);
    final contractAddress = coin.contractAddress;
    final coinAddress = _walletRepository.walletGetAddressForCoin(coinType);

    final privateKeyEth = _walletRepository.getKeyForCoin(coinType).toList();

    try {
      // Receive nonce
      final nonceResponse = await _http.post(
        Uri.parse(_testUrl),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionCount',
          'params': [coinAddress, 'latest'],
          // TODO: get response ID
          'id': 1,
        }),
      );

      if (nonceResponse.statusCode == 200) {
        final nonceResult = Result.fromJson(jsonDecode(nonceResponse.body)).result;

        final nonce = _bigIntToUint8List(BigInt.parse(nonceResult.substring(2), radix: 16));

        // Returns the current price per gas in wei.
        final gasPriceResponse = await _http.post(
          Uri.parse(_testUrl),
          headers: {
            HttpHeaders.contentTypeHeader: ContentType.json.toString(),
          },
          body: jsonEncode({
            'jsonrpc': '2.0',
            'method': 'eth_gasPrice',
            'params': [],
            'id': 1,
          }),
        );

        if (gasPriceResponse.statusCode == 200) {
          final gasPriceResult = Result.fromJson(jsonDecode(gasPriceResponse.body)).result;
          var gasPriceBigInt = BigInt.parse(gasPriceResult);
          final gasPrice = _bigIntToUint8List(gasPriceBigInt);

          // Получаем keccak хэш для метода `transfer(address,uint256)`
          final Uint8List list = keccakUtf8('transfer(address,uint256)');
          final hexString = hex.encode(list);
          final methodHex = hexString.substring(0, 8); // Первые 4 байта сигнатуры

          // Формируем данные транзакции (вызов метода `transfer`)
          final data = '0x$methodHex'
              '000000000000000000000000${toAddress.substring(2)}' // Адрес получателя
              '${amountInMinUnits.toRadixString(16).padLeft(64, '0')}'; // Сумма перевода

          final fromAddress = getAddress(coinType);

          final estimatedGasResponse = await _http.post(
            Uri.parse(_testUrl),
            headers: {
              HttpHeaders.contentTypeHeader: ContentType.json.toString(),
            },
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'eth_estimateGas',
              'params': [
                {
                  'from': fromAddress,
                  'to': contractAddress,
                  'value': '0x0',
                  'data': data,
                },
                'latest'
              ],
              'id': 1,
            }),
          );

          if (gasPriceResponse.statusCode != 200) {
            throw Exception('Failed to send transaction ${estimatedGasResponse.reasonPhrase}');
          }

          final estimatedGas = Result.fromJson(jsonDecode(estimatedGasResponse.body)).result;

          final gasLimit = _bigIntToUint8List(BigInt.parse(estimatedGas));

          final erc20Transfer = ethereum.Transaction_ERC20Transfer(
            to: toAddress,
            amount: _bigIntToUint8List(amountInMinUnits), // Закодированное количество токенов
          );

          final transaction = ethereum.Transaction(
            erc20Transfer: erc20Transfer, // Указываем поле erc20Transfer
          );

          final chainId = _bigIntToUint8List(BigInt.parse('0x1')); // MainNet

          final signedTransaction = ethereum.SigningInput(
            chainId: chainId,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            toAddress: contractAddress,
            transaction: transaction,
            privateKey: privateKeyEth,
            nonce: nonce,
          );

          TWCoinType coin = TWCoinType.TWCoinTypeEthereum;
          final sign = _walletRepository.sign(signedTransaction.writeToBuffer(), coin);
          final signingOutput = ethereum.SigningOutput.fromBuffer(sign);
          final rawTx = Utils.bytesToHex(signingOutput.encoded);

          return _sendRawTransaction(rawTx);
        } else {
          throw Exception('Failed to send transaction ${gasPriceResponse.reasonPhrase}');
        }
      } else {
        throw Exception('Failed to send transaction ${nonceResponse.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Uint8List _bigIntToUint8List(BigInt bigInt) {
    int byteLength = (bigInt.bitLength + 7) >> 3;
    final bytes = Uint8List(byteLength);

    BigInt mask = BigInt.from(0xff);

    for (int i = 0; i < byteLength; i++) {
      // Приведение BigInt к int перед присвоением в массив Uint8List
      bytes[byteLength - i - 1] = (bigInt & mask).toInt();
      bigInt = bigInt >> 8;
    }

    return bytes;
  }

  Uint8List _intToUint8List(int value) {
    // Определяем количество байт, необходимых для представления int
    int byteLength = (value.bitLength + 7) >> 3;

    // Создаем Uint8List с нужной длиной
    final bytes = Uint8List(byteLength);

    // Заполняем массив байтами из числа
    for (int i = 0; i < byteLength; i++) {
      bytes[byteLength - i - 1] = (value >> (8 * i)) & 0xff;
    }

    return bytes;
  }

  Future<String> _sendRawTransaction(String rawTx, [bool test = false]) async {
    final response = await _http.post(
      Uri.parse(test ? _testUrl : _testUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'eth_sendRawTransaction',
        'params': ['0x$rawTx'],
        'id': 1,
      }),
    );

    return Result.fromJson(jsonDecode(response.body)).result;
  }
}
