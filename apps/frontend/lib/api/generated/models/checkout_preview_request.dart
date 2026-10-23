// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'checkout_preview_request.g.dart';

@JsonSerializable()
class CheckoutPreviewRequest {
  const CheckoutPreviewRequest({required this.addressId, this.listingIds});

  factory CheckoutPreviewRequest.fromJson(Map<String, Object?> json) =>
      _$CheckoutPreviewRequestFromJson(json);

  final int addressId;
  final List<int>? listingIds;

  Map<String, Object?> toJson() => _$CheckoutPreviewRequestToJson(this);
}
