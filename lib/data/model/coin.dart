import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wallet_test/data/model/coin_type.dart';

part 'coin.freezed.dart';
part 'coin.g.dart';

@freezed
class Coin with _$Coin {
  const factory Coin({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'type') required CoinType type,
    @JsonKey(name: 'blockchain') required String blockchain,
    @JsonKey(name: 'decimals') required int decimals,
    @JsonKey(name: 'contractAddress') String? contractAddress,
  }) = _Coin;

  factory Coin.fromJson(Map<String, dynamic> json) => _$CoinFromJson(json);
}
