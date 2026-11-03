// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/file_response.dart';

part 'files_client.g.dart';

@RestApi()
abstract class FilesClient {
  factory FilesClient(Dio dio, {String? baseUrl}) = _FilesClient;

  /// Tải ảnh lên (PNG / JPEG / WebP, tối đa 5MB). Trả về URL tương đối để gắn vào nghiệp vụ
  @MultiPart()
  @POST('/files')
  Future<FileResponse> postFiles({
    @Part(name: 'file') required MultipartFile file,
  });

  /// Xem ảnh đã tải lên
  @GET('/files/{name}')
  @DioResponseType(ResponseType.stream)
  Stream<String> getFilesName({@Path('name') required String name});
}
