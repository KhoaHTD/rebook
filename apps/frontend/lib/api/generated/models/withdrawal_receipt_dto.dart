// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'withdrawal_receipt_dto.g.dart';

/// Biên lai chuyển khoản Admin nhập khi duyệt rút tiền (SRS 8.1). Người bán xem được trong lịch sử rút tiền.
@JsonSerializable()
class WithdrawalReceiptDto {
  const WithdrawalReceiptDto({
    required this.senderName,
    required this.transferredAt,
    required this.amount,
    required this.proofImageUrl,
  });

  factory WithdrawalReceiptDto.fromJson(Map<String, Object?> json) =>
      _$WithdrawalReceiptDtoFromJson(json);

  final String senderName;
  final DateTime transferredAt;

  /// Phải đúng số tiền yêu cầu.
  final int amount;
  final String proofImageUrl;

  Map<String, Object?> toJson() => _$WithdrawalReceiptDtoToJson(this);
}
