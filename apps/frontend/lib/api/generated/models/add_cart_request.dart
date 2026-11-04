// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'add_cart_request.g.dart';

@JsonSerializable()
class AddCartRequest {
  const AddCartRequest({required this.listingId, required this.quantity});

  factory AddCartRequest.fromJson(Map<String, Object?> json) =>
      _$AddCartRequestFromJson(json);

  final int listingId;
  final int quantity;

  Map<String, Object?> toJson() => _$AddCartRequestToJson(this);
}
