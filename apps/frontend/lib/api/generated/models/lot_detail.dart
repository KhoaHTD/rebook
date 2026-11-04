// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_response.dart';
import 'lot_public.dart';
import 'session_summary.dart';

part 'lot_detail.g.dart';

@JsonSerializable()
class LotDetail {
  const LotDetail({
    this.lot,
    this.book,
    this.conditionReport,
    this.checklist,
    this.provenance,
    this.session,
  });

  factory LotDetail.fromJson(Map<String, Object?> json) =>
      _$LotDetailFromJson(json);

  final LotPublic? lot;
  final BookResponse? book;
  final String? conditionReport;
  final Map<String, dynamic>? checklist;
  final String? provenance;
  final SessionSummary? session;

  Map<String, Object?> toJson() => _$LotDetailToJson(this);
}
