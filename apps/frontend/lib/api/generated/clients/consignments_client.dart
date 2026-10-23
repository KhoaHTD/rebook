// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/appointment_request.dart';
import '../models/appointment_slot_dto.dart';
import '../models/consignment_decision_request.dart';
import '../models/consignment_dto.dart';
import '../models/consignment_request.dart';
import '../models/unsold_choice_request.dart';

part 'consignments_client.g.dart';

@RestApi()
abstract class ConsignmentsClient {
  factory ConsignmentsClient(Dio dio, {String? baseUrl}) = _ConsignmentsClient;

  @GET('/consignments')
  Future<List<ConsignmentDto>> listMyConsignments();

  @POST('/consignments')
  Future<ConsignmentDto> createConsignment({
    @Body() required ConsignmentRequest body,
  });

  @GET('/consignments/{id}')
  Future<ConsignmentDto> getConsignment({@Path('id') required String id});

  @GET('/consignments/{id}/appointment-slots')
  Future<List<AppointmentSlotDto>> listAppointmentSlots({
    @Path('id') required String id,
  });

  @POST('/consignments/{id}/appointment')
  Future<ConsignmentDto> bookAppointment({
    @Path('id') required String id,
    @Body() required AppointmentRequest body,
  });

  @POST('/consignments/{id}/decision')
  Future<ConsignmentDto> decideConsignment({
    @Path('id') required String id,
    @Body() required ConsignmentDecisionRequest body,
  });

  /// Lô không bán được — vào phiên sau / chuyển bán giá cố định / nhận lại.
  @POST('/consignments/{id}/after-auction')
  Future<ConsignmentDto> chooseAfterUnsold({
    @Path('id') required String id,
    @Body() required UnsoldChoiceRequest body,
  });
}
