// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'approval_request.g.dart';

@JsonSerializable()
class ApprovalRequest {
  const ApprovalRequest({required this.approve, this.reason});

  factory ApprovalRequest.fromJson(Map<String, Object?> json) =>
      _$ApprovalRequestFromJson(json);

  final bool approve;
  final String? reason;

  Map<String, Object?> toJson() => _$ApprovalRequestToJson(this);
}
