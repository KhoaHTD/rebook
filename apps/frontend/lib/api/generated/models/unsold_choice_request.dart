// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'unsold_choice.dart';

part 'unsold_choice_request.g.dart';

@JsonSerializable()
class UnsoldChoiceRequest {
  const UnsoldChoiceRequest({
    required this.choice,
    this.newReserve,
    this.fixedPrice,
  });

  factory UnsoldChoiceRequest.fromJson(Map<String, Object?> json) =>
      _$UnsoldChoiceRequestFromJson(json);

  final UnsoldChoice choice;
  final int? newReserve;
  final int? fixedPrice;

  Map<String, Object?> toJson() => _$UnsoldChoiceRequestToJson(this);
}
