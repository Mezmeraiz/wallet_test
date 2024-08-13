import 'package:freezed_annotation/freezed_annotation.dart';

part 'bitcoin_address_info.freezed.dart';
part 'bitcoin_address_info.g.dart';

@freezed
class BitcoinAddressInfo with _$BitcoinAddressInfo {
  const factory BitcoinAddressInfo({
    @JsonKey(name: 'page') int? page,
    @JsonKey(name: 'totalPages') int? totalPages,
    @JsonKey(name: 'itemsOnPage') int? itemsOnPage,
    @JsonKey(name: 'address') String? address,
    @JsonKey(name: 'balance') String? balance,
    @JsonKey(name: 'totalReceived') String? totalReceived,
    @JsonKey(name: 'totalSent') String? totalSent,
    @JsonKey(name: 'unconfirmedBalance') String? unconfirmedBalance,
    @JsonKey(name: 'unconfirmedTxs') int? unconfirmedTxs,
    @JsonKey(name: 'txs') int? txs,
    @JsonKey(name: 'txids') List<String>? txids,
  }) = _BitcoinAddressInfo;

  factory BitcoinAddressInfo.fromJson(Map<String, dynamic> json) => _$BitcoinAddressInfoFromJson(json);
}
