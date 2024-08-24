import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';
part 'result.g.dart';

@Freezed(
  copyWith: false,
  toJson: false,
  equal: false,
  toStringOverride: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class Result with _$Result {
  const factory Result({
    @JsonKey(name: 'result') @Default('') String result,
  }) = _Result;

  factory Result.fromJson(Map<String, dynamic> json) => _$ResultFromJson(json);
}
