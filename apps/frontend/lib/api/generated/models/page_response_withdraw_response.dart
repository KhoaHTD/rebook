// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'withdraw_response.dart';

part 'page_response_withdraw_response.g.dart';

@JsonSerializable()
class PageResponseWithdrawResponse {
  const PageResponseWithdrawResponse({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseWithdrawResponse.fromJson(Map<String, Object?> json) =>
      _$PageResponseWithdrawResponseFromJson(json);

  final List<WithdrawResponse>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseWithdrawResponseToJson(this);
}
