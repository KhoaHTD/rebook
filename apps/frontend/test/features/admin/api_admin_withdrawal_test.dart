import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/features/admin/data/api_admin_repository.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';

/// Bắt request gửi đi để kiểm tra nội dung, trả về một yêu cầu rút tiền hợp lệ.
class _Capture implements HttpClientAdapter {
  Map<String, dynamic>? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    body = options.data as Map<String, dynamic>?;
    return ResponseBody.fromString(
      jsonEncode({
        'id': 1,
        'userId': 3,
        'userName': 'Trần Minh Thư',
        'amount': 60000,
        'bankName': 'Vietcombank',
        'accountNumber': '123456789',
        'accountHolder': 'TRAN MINH THU',
        'status': 'APPROVED',
        'createdAt': '2026-11-05T04:07:00Z',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'biên lai rút tiền gửi giờ chuyển khoản dạng UTC (có múi giờ)',
    () async {
      final capture = _Capture();
      final repo = ApiAdminRepository(
        api.RestClient(Dio()..httpClientAdapter = capture),
      );
      // Giờ máy (không có múi giờ), đúng như màn biên lai của Admin tạo ra.
      final local = DateTime(2026, 11, 5, 10, 24, 1);
      await repo.completeWithdrawal(
        '1',
        WithdrawalReceipt(
          senderName: 'ReBook',
          transferredAt: local,
          amount: 60000,
          proofImageUrl: 'https://example.com/proof.png',
        ),
      );
      final sent = capture.body!['transferTime'] as String;
      expect(sent.endsWith('Z'), isTrue, reason: 'backend cần Instant: $sent');
      expect(DateTime.parse(sent).isAtSameMomentAs(local), isTrue);
    },
  );
}
