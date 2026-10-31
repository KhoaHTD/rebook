// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'signature_status.dart';

part 'inspection_checklist_dto.g.dart';

@JsonSerializable()
class InspectionChecklistDto {
  const InspectionChecklistDto({
    required this.fullPages,
    required this.correctEdition,
    required this.coverOk,
    required this.spineOk,
    required this.pagesOk,
    required this.noMold,
    required this.hasNotes,
    required this.signature,
  });

  factory InspectionChecklistDto.fromJson(Map<String, Object?> json) =>
      _$InspectionChecklistDtoFromJson(json);

  final bool fullPages;
  final bool correctEdition;
  final bool coverOk;
  final bool spineOk;
  final bool pagesOk;
  final bool noMold;
  final bool hasNotes;
  final SignatureStatus signature;

  Map<String, Object?> toJson() => _$InspectionChecklistDtoToJson(this);
}
