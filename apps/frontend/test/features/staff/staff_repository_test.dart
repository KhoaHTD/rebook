import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/staff/data/fake_staff_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

void main() {
  late FakeStore store;
  tearDown(() => store.dispose());

  test(
    'staff: nhận sách bằng mã → kiểm định đạt → người gửi thấy phiếu',
    () async {
      store = FakeStore()..login('staff@rebook.vn', '123456');
      final repo = FakeStaffRepository(store);
      final appts = await repo.appointments();
      expect(appts, isNotEmpty);
      final c = await repo.checkIn(
        appts.first.appointmentCode!,
        receiptImageUrls: const ['r1'],
      );
      expect(c.status, ConsignmentStatus.received);
      expect(c.warehouseCode, isNotNull);

      final inspected = await repo.submitInspection(
        c.id,
        const InspectionDraft(
          result: InspectionResult.pass,
          checklist: InspectionChecklist(
            fullPages: true,
            correctEdition: true,
            coverOk: true,
            spineOk: true,
            pagesOk: true,
            noMold: true,
            hasNotes: false,
            signature: SignatureStatus.none,
          ),
          condition: ConditionGrade.veryGood,
          conditionReport: 'Gáy hơi sờn.',
          staffImageUrls: ['s1'],
          estimateLow: 400000,
          estimateHigh: 700000,
          proposedStart: 300000,
          proposedReserve: 350000,
        ),
      );
      expect(inspected.status, ConsignmentStatus.inspected);
      expect(
        (await repo.warehouse()).any((w) => w.consignmentId == c.id),
        isTrue,
      );
    },
  );
}
