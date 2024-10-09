import 'dart:async';
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
import 'package:wallet_test/protobuf/Tron.pb.dart' as tron;
import 'package:web3dart/crypto.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;

const String _tronUrl = 'https://api.trongrid.io/jsonrpc';
const String _tronRestUrl = 'https://api.trongrid.io';
//const String _tronRestUrl = 'https://rpc.ankr.com/http/tron';

const String _testUrl = 'https://rpc.ankr.com/tron_jsonrpc';
//const String _tronUrl = 'https://rpc.ankr.com/bsc_testnet_chapel';

final class TronWallet extends BaseBlockchainWallet {
  final InterceptedHttp _http;
  final WalletRepository _walletRepository;

  TronWallet({
    required InterceptedHttp http,
    required super.walletRepository,
  })  : _http = http,
        _walletRepository = walletRepository;

  // Future<Map<String, dynamic>?> _createTronTransaction(
  Future<String> _createTronTransaction(
    String fromAddress,
    String toAddress,
    int amountInSun,
  ) async {
    final url = '$_tronRestUrl/wallet/createtransaction';
    final body = jsonEncode({
      'owner_address': '41' + _tronAddressToHex(fromAddress).substring(2),
      'to_address': '41' + _tronAddressToHex(toAddress).substring(2),
      'amount': amountInSun,
    });

    final response = await _http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      //var g = jsonDecode(response.body);
      return response.body;
    } else {
      print('Failed to create transaction: ${response.body}');
      return '';
    }
  }

// Пример функции отправки транзакции в TRON
  Future<String> sendTronTransaction(
    Coin coin,
    String toAddress,
    String amount,
  ) async {
    final amountInSun = Utils.valueToMinUnit(double.parse(amount), coin.decimals);

    final fromAddress = getAddress(TWCoinType.TWCoinTypeTron);
    final privateKey = _walletRepository.getKeyForCoin(TWCoinType.TWCoinTypeTron).toList();

    try {
      var createdTransaction = await _createTronTransaction(fromAddress, toAddress, amountInSun.toInt());

      print(createdTransaction);

      // Создание контракта передачи средств
      final transferContract = tron.TransferContract(
        ownerAddress: fromAddress,
        toAddress: toAddress,
        amount: $fixnum.Int64(amountInSun.toInt()), // Используем Int64 для указания суммы в Sun
      );

      final blockData = await getLatestBlock();
      final rawData = blockData['block_header']['raw_data'];
      final int blockNumber = rawData['number'];

      final String txTrieRoot = rawData['txTrieRoot'];
      final String parentHash = rawData['parentHash'];
      final String witnessAddress = rawData['witness_address'];
      final int version = rawData['version'];

      final blockHeader = tron.BlockHeader(
        number: $fixnum.Int64(blockNumber),
        txTrieRoot: hexToBytes(txTrieRoot),
        parentHash: hexToBytes(parentHash),
        witnessAddress: hexToBytes(witnessAddress),
        version: version,
        timestamp: $fixnum.Int64(DateTime.now().millisecondsSinceEpoch),
      );

      print(blockHeader);

      // Создание транзакции
      final transaction = tron.Transaction(
        transfer: transferContract,
        blockHeader: blockHeader,
        feeLimit: $fixnum.Int64(1000000), // Установка лимита комиссии (1,000,000 Sun = 1 TRX)
        timestamp: $fixnum.Int64(DateTime.now().millisecondsSinceEpoch),
        expiration: $fixnum.Int64(DateTime.now().millisecondsSinceEpoch + 36000000), // Время жизни транзакции
      );

      // Подготовка данных для подписания транзакции
      final signedTransaction = tron.SigningInput(
        transaction: transaction,
        privateKey: privateKey, // Преобразование приватного ключа в байты
      );

      TWCoinType coin = TWCoinType.TWCoinTypeTron;
      final sign = _walletRepository.sign(signedTransaction.writeToBuffer(), coin);
      final signingOutput = tron.SigningOutput.fromBuffer(sign);
      var rawTx = signingOutput.json;
      print(rawTx);
      // var f = signingOutput.json;
      // //final rawTx = Utils.bytesToHex(signingOutput.encoded);

      // Отправка подписанной транзакции
      return await _sendRawTronTransaction(rawTx);
    } catch (e) {
      throw Exception('Failed to send transaction: $e');
    }
  }

  Future<String> _sendRawTronTransaction(String tx) async {
    final response = await _http.post(
      Uri.parse('$_tronRestUrl/wallet/broadcasttransaction'),
      headers: {'Content-Type': 'application/json'},
      body: tx,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      print('body = $result');
      if (result['result'] == true) {
        return result['txid']; // Возвращаем ID транзакции, если отправка успешна
      } else {
        throw Exception('Failed to broadcast transaction: ${result['message']}');
      }
    } else {
      throw Exception('Failed to broadcast transaction: ${response.reasonPhrase}');
    }
  }

  // Функция для получения информации о последнем блоке
  Future<Map<String, dynamic>> getLatestBlock() async {
    final response = await _http.get(
      Uri.parse('$_tronRestUrl/wallet/getnowblock'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to retrieve latest block information');
    }
  }

// // Пример функции отправки raw-транзакции в TRON
//   Future<String> _sendRawTransaction(Uint8List signedTx) async {
//     final response = await http.post(
//       Uri.parse('$_tronUrl/wallet/broadcasttransaction'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'transaction': bytesToHex(signedTx)}),
//     );
//
//     if (response.statusCode == 200) {
//       final result = jsonDecode(response.body);
//       if (result['result'] == true) {
//         return result['txid']; // Возвращаем ID транзакции, если отправка успешна
//       } else {
//         throw Exception('Failed to broadcast transaction: ${result['message']}');
//       }
//     } else {
//       throw Exception('Failed to broadcast transaction: ${response.reasonPhrase}');
//     }
//   }
//
// // Функции для преобразования приватного ключа и адреса
//   String getTronAddressFromPrivateKey(String privateKey) {
//     // Получение TRON адреса из приватного ключа
//     // Используйте методы библиотеки Trust Wallet Core или другого подходящего инструмента
//     return "TRON_ADDRESS";
//   }
//
//   Uint8List hexToBytes(String hex) {
//     // Преобразование строки hex в байты
//     final buffer = Uint8List(hex.length ~/ 2);
//     for (var i = 0; i < hex.length; i += 2) {
//       buffer[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
//     }
//     return buffer;
//   }
//
//   String bytesToHex(Uint8List bytes) {
//     // Преобразование байтов в строку hex
//     final buffer = StringBuffer();
//     for (var byte in bytes) {
//       buffer.write(byte.toRadixString(16).padLeft(2, '0'));
//     }
//     return buffer.toString();
//   }
//
//   Uint8List signTronTransaction(Uint8List transactionBytes) {
//     // Подпись транзакции с помощью приватного ключа
//     // Используйте Trust Wallet Core или другую библиотеку для подписи
//     return transactionBytes; // Возвращаем подписанные байты
//   }

  Future<String> _sendTransaction(
    Coin coin,
    String toAddress,
    String amount,
  ) async {
    // Переводим значение в минимальную единицу (обычно Wei)
    final amountInWei = Utils.valueToMinUnit(double.parse(amount), coin.decimals);

    // Получаем адрес и приватный ключ для BSC
    final addressBsc = getAddress(TWCoinType.TWCoinTypeTron);
    final privateKeyBsc = _walletRepository.getKeyForCoin(TWCoinType.TWCoinTypeTron).toList();

    final hexAddressTron = _tronAddressToHex(addressBsc); // Преобразуем адрес отправителя
    final hexToAddress = _tronAddressToHex(toAddress);

    try {
      // Получение nonce
      final nonceResponse = await _http.post(
        Uri.parse(_tronUrl),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionCount',
          'params': [hexAddressTron, 'latest'],
          'id': 1,
        }),
      );

      if (nonceResponse.statusCode == 200) {
        var f = jsonDecode(nonceResponse.body);
        final nonceResult = Result.fromJson(jsonDecode(nonceResponse.body)).result;
        final nonce = _bigIntToUint8List(BigInt.parse(nonceResult.substring(2), radix: 16));

        // Получение текущей цены газа
        final gasPriceResponse = await _http.post(
          Uri.parse(_tronUrl),
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

          // Формирование транзакции
          final transaction = ethereum.Transaction(
            transfer: ethereum.Transaction_Transfer(
              amount: _bigIntToUint8List(amountInWei),
            ),
          );

          // Указываем chainId для Binance Smart Chain (Mainnet: 56, Testnet: 97)
          final chainId = _bigIntToUint8List(BigInt.from(97)); // TestNet BSC

          final t = tron.Transaction(
            transfer: tron.TransferContract(),
          );

          final s = tron.SigningInput();

          // Подписываем транзакцию
          final signedTransaction = ethereum.SigningInput(
            chainId: chainId,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            toAddress: hexToAddress,
            transaction: transaction,
            privateKey: privateKeyBsc,
            nonce: nonce,
          );

          // Указываем тип монеты для BSC
          TWCoinType coin = TWCoinType.TWCoinTypeSmartChain;
          final sign = _walletRepository.sign(signedTransaction.writeToBuffer(), coin);
          final signingOutput = ethereum.SigningOutput.fromBuffer(sign);
          final rawTx = Utils.bytesToHex(signingOutput.encoded);

          // Отправка сырой транзакции в сеть
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
        Uri.parse(_tronUrl),
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
          Uri.parse(_tronUrl),
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
            Uri.parse(_tronUrl),
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
              ],
              'id': 1,
            }),
          );

          if (estimatedGasResponse.statusCode != 200) {
            throw Exception('Failed to send transaction ${estimatedGasResponse.reasonPhrase}');
          }

          var f = jsonDecode(estimatedGasResponse.body);

          final estimatedGas = Result.fromJson(jsonDecode(estimatedGasResponse.body)).result;

          final gasLimit = _bigIntToUint8List(BigInt.parse(estimatedGas));

          final erc20Transfer = ethereum.Transaction_ERC20Transfer(
            to: toAddress,
            amount: _bigIntToUint8List(amountInMinUnits), // Закодированное количество токенов
          );

          final transaction = ethereum.Transaction(
            erc20Transfer: erc20Transfer, // Указываем поле erc20Transfer
          );

          final chainId = _bigIntToUint8List(BigInt.from(56)); // MainNet

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
      Uri.parse(test ? _tronUrl : _tronUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'eth_sendRawTransaction',
        'params': ['0x$rawTx'],
        'id': 1,
      }),
    );

    var f = jsonDecode(response.body);

    return Result.fromJson(jsonDecode(response.body)).result;
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
        CoinType.coin => sendTronTransaction(
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
  Future<void> loadCoinInfo(List<Coin> coin) async {
    // TODO: implement loadCoinInfo
  }

  String _tronAddressToHex(String tronAddress) {
    // Декодирование Tron-адреса из Base58 в байты
    final base58Decoded = base58Decode(tronAddress);

    // Tron-адрес в байтах должен начинаться с 0x41 (это указывает на адрес Tron)
    // Убираем первый байт (0x41) и возвращаем 20 байт адреса
    final addressBytes = base58Decoded.sublist(1, 21);

    // Конвертируем в Hex строку и добавляем '0x'
    return '0x${bytesToHex(addressBytes)}';
  }

  List<int> base58Decode(String input) {
    const String base58Alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    final List<int> decoded = [0];

    for (int i = 0; i < input.length; i++) {
      int carry = base58Alphabet.indexOf(input[i]);
      if (carry == -1) throw FormatException("Invalid Base58 character");

      for (int j = 0; j < decoded.length; j++) {
        carry += decoded[j] * 58;
        decoded[j] = carry % 256;
        carry ~/= 256;
      }

      while (carry > 0) {
        decoded.add(carry % 256);
        carry ~/= 256;
      }
    }

    // Возвращаем байты, перевернув список, чтобы получить в нужном порядке
    return decoded.reversed.toList();
  }

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
    final address = getAddress(CoinUtils.getCoinTypeFromBlockchain(coin.blockchain));
    final payload = {
      'jsonrpc': '2.0',
      'method': 'eth_getBalance',
      'params': [_tronAddressToHex(address), 'latest'],
      // TODO: get response ID
      'id': 1,
    };

    try {
      final response = await _http.post(
        Uri.parse(_tronUrl),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        var f = jsonDecode(response.body);
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

  Future<double> _getTokenBalance(Coin coin) async {
    final coinType = CoinUtils.getCoinTypeFromBlockchain(coin.blockchain);
    final contractAddress = _tronAddressToHex(coin.contractAddress!);
    final coinAddress = _walletRepository.walletGetAddressForCoin(coinType);

    // Преобразование адреса Tron в формат Hex без префикса
    final hexCoinAddress = _tronAddressToHex(coinAddress).substring(2);

    // Генерируем хэш для метода balanceOf
    final Uint8List list = keccakUtf8('balanceOf(address)');
    final hexString = bytesToHex(list);
    final methodHex = hexString.substring(0, 8);
    final data = '0x${methodHex}000000000000000000000000$hexCoinAddress';

    // Создаем параметры для вызова
    final param = {
      'to': contractAddress,
      'data': data,
    };

    final payload = {
      'jsonrpc': '2.0',
      'method': 'eth_call',
      'params': [param, 'latest'],
      'id': 1,
    };

    try {
      final response = await _http.post(
        Uri.parse(_tronUrl),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        var result = responseBody['result'] as String?;

        if (result == null || result.isEmpty) {
          return 0.0;
        }

        result = result.replaceFirst('0x', '');
        final balance = BigInt.parse(result, radix: 16);
        final tokenBalance = balance / BigInt.from(10).pow(coin.decimals);

        return tokenBalance.toDouble();
      } else {
        throw Exception('Failed to load balance: ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
