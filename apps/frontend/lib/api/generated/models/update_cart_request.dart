// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_cart_request.g.dart';

@JsonSerializable()
class UpdateCartRequest {
  const UpdateCartRequest({required this.quantity});

  factory UpdateCartRequest.fromJson(Map<String, Object?> json) =>
      _$UpdateCartRequestFromJson(json);

  final int quantity;

  Map<String, Object?> toJson() => _$UpdateCartRequestToJson(this);
}
