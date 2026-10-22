import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/sell/data/fake_sell_repository.dart';
import 'package:book_marketplace/features/sell/data/sell_repository_provider.dart';
import 'package:book_marketplace/features/sell/domain/sell_draft.dart';
import 'package:book_marketplace/features/sell/presentation/providers/sell_providers.dart';
import 'package:book_marketplace/shared/domain/book.dart';

void main() {
  late ProviderContainer container;
  late FakeSellRepository repo;

  setUp(() {
    repo = FakeSellRepository(latency: Duration.zero);
    container = ProviderContainer(
      overrides: [sellRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(sellFormProvider, (_, _) {});
  });

  test('phí sàn 5% và số tiền thực nhận', () {
    const draft = SellDraft(price: 65000);
    expect(draft.fee, 3250);
    expect(draft.net, 61750);
  });

  test('nút +/− đổi giá theo bước 5.000đ, không xuống dưới 5.000đ', () {
    final form = container.read(sellFormProvider.notifier);
    form.increase();
    expect(container.read(sellFormProvider).price, 70000);
    form.setPrice(5000);
    form.decrease();
    expect(container.read(sellFormProvider).price, 5000);
  });

  test('thêm / thay / xoá ảnh theo ô', () {
    final form = container.read(sellFormProvider.notifier);
    form.setPhoto(0, 'a');
    form.setPhoto(5, 'b'); // ô trống → thêm vào cuối
    form.setPhoto(0, 'c'); // thay
    expect(container.read(sellFormProvider).imageUrls, ['c', 'b']);
    form.setPhoto(0, ''); // xoá
    expect(container.read(sellFormProvider).imageUrls, ['b']);
  });

  test('giá gợi ý theo tình trạng, điểm giữa làm tròn theo bước', () async {
    final form = container.read(sellFormProvider.notifier);
    container.listen(priceSuggestionProvider, (_, _) {});
    expect(await container.read(priceSuggestionProvider.future), isNull);

    form.setTitle('Nhà giả kim');
    form.setCondition(BookCondition.good);
    final s = await container.read(priceSuggestionProvider.future);
    expect(s, const PriceSuggestion(low: 30000, high: 45000));
    expect(s!.mid, 40000);
  });

  test(
    'đăng tin thiếu tên / tác giả thì báo lỗi, đủ thì gửi và xoá form',
    () async {
      container.listen(submitListingProvider, (_, _) {});
      final submit = container.read(submitListingProvider.notifier);
      expect(await submit.submit(), isFalse);

      container.read(sellFormProvider.notifier)
        ..setTitle('Nhà giả kim')
        ..setAuthor('Paulo Coelho')
        ..setCategory(const SellCategory(id: '3', name: 'Văn học nước ngoài'));
      // Chưa đủ 3 ảnh → vẫn chưa hợp lệ
      expect(container.read(sellFormProvider).isValid, isFalse);
      for (var i = 0; i < 3; i++) {
        container
            .read(sellFormProvider.notifier)
            .setPhoto(i, 'https://img/$i.jpg');
      }
      expect(await submit.submit(), isTrue);
      expect(repo.created.single.title, 'Nhà giả kim');
      expect(container.read(sellFormProvider).title, isEmpty);
    },
  );
}
