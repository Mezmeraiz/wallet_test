import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_preview.freezed.dart';
part 'transaction_preview.g.dart';

@freezed
class TransactionPreview with _$TransactionPreview {
  const TransactionPreview._();

  const factory TransactionPreview({
    @Default(TransactionType.send) TransactionType type,
    @Default('') String address,
    @Default(0) double count,
  }) = _TransactionPreview;

  factory TransactionPreview.fromJson(Map<String, dynamic> json) => _$TransactionPreviewFromJson(json);
}

enum TransactionType {
  send,
  receive,
}
