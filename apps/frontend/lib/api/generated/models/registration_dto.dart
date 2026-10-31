// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'registration_status.dart';

part 'registration_dto.g.dart';

@JsonSerializable()
class RegistrationDto {
  const RegistrationDto({
    required this.id,
    required this.sessionId,
    required this.sessionTitle,
    required this.paddleNumber,
    required this.depositAmount,
    required this.bidLimit,
    required this.committedAmount,
    required this.status,
  });

  factory RegistrationDto.fromJson(Map<String, Object?> json) =>
      _$RegistrationDtoFromJson(json);

  final String id;
  final String sessionId;
  final String sessionTitle;

  /// vd #027
  final String paddleNumber;
  final int depositAmount;

  /// Cọc × hệ số (mặc định 10)
  final int bidLimit;

  /// Tổng giá đang giữ / đã thắng trong phiên
  final int committedAmount;
  final RegistrationStatus status;

  Map<String, Object?> toJson() => _$RegistrationDtoToJson(this);
}
