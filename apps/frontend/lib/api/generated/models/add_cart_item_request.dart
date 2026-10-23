// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'add_cart_item_request.g.dart';

@JsonSerializable()
class AddCartItemRequest {
  const AddCartItemRequest({required this.listingId, required this.quantity});

  factory AddCartItemRequest.fromJson(Map<String, Object?> json) =>
      _$AddCartItemRequestFromJson(json);

  final String listingId;
  final int quantity;

  Map<String, Object?> toJson() => _$AddCartItemRequestToJson(this);
}
