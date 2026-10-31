// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/upload_signature_dto.dart';
import '../models/upload_signature_request.dart';

part 'uploads_client.g.dart';

@RestApi()
abstract class UploadsClient {
  factory UploadsClient(Dio dio, {String? baseUrl}) = _UploadsClient;

  /// Chữ ký để app upload ảnh thẳng lên Cloudinary; backend chỉ lưu URL.
  @POST('/uploads/signature')
  Future<UploadSignatureDto> createUploadSignature({
    @Body() required UploadSignatureRequest body,
  });
}
