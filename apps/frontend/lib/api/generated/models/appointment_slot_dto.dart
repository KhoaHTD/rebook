// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'appointment_slot_dto.g.dart';

@JsonSerializable()
class AppointmentSlotDto {
  const AppointmentSlotDto({required this.startAt, required this.available});

  factory AppointmentSlotDto.fromJson(Map<String, Object?> json) =>
      _$AppointmentSlotDtoFromJson(json);

  final DateTime startAt;
  final bool available;

  Map<String, Object?> toJson() => _$AppointmentSlotDtoToJson(this);
}
