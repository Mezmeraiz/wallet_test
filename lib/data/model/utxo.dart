import 'package:freezed_annotation/freezed_annotation.dart';

part 'utxo.freezed.dart';
part 'utxo.g.dart';

@freezed
class Utxo with _$Utxo {
  const Utxo._();

  const factory Utxo({
    @JsonKey(name: 'txid') @Default('') String txid,
    @JsonKey(name: 'vout') @Default(0) int vout,
    @JsonKey(name: 'value') @Default('') String value,
    @JsonKey(name: 'height') @Default(0) int height,
    @JsonKey(name: 'confirmations') @Default(0) int confirmations,
  }) = _Utxo;

  factory Utxo.fromJson(Map<String, dynamic> json) => _$UtxoFromJson(json);
}
