// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'category_slice.g.dart';

@JsonSerializable()
class CategorySlice {
  const CategorySlice({this.name, this.amount});

  factory CategorySlice.fromJson(Map<String, Object?> json) =>
      _$CategorySliceFromJson(json);

  final String? name;
  final num? amount;

  Map<String, Object?> toJson() => _$CategorySliceToJson(this);
}
