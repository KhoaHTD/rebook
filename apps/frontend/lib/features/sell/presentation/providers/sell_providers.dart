import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/features/sell/data/sell_repository_provider.dart';
import 'package:book_marketplace/features/sell/domain/sell_draft.dart';
import 'package:book_marketplace/shared/domain/book.dart';

part 'sell_providers.g.dart';

/// Nội dung form Đăng bán.
@riverpod
class SellForm extends _$SellForm {
  @override
  SellDraft build() => const SellDraft();

  void setTitle(String v) => state = state.copyWith(title: v);
  void setAuthor(String v) => state = state.copyWith(author: v);
  void setPublisher(String v) => state = state.copyWith(publisher: v);
  void setYear(String v) =>
      state = state.copyWith(publishYear: int.tryParse(v));
  void setCondition(BookCondition c) => state = state.copyWith(condition: c);
  void setCategory(SellCategory c) => state = state.copyWith(category: c);
  void setWeight(String v) =>
      state = state.copyWith(weightGram: int.tryParse(v) ?? 0);

  /// Đặt / thay ảnh ở ô [index]; chuỗi rỗng = xoá ảnh đó.
  void setPhoto(int index, String url) {
    final photos = [...state.imageUrls];
    final value = url.trim();
    if (index < photos.length) {
      if (value.isEmpty) {
        photos.removeAt(index);
      } else {
        photos[index] = value;
      }
    } else if (value.isNotEmpty && photos.length < SellDraft.maxPhotos) {
      photos.add(value);
    }
    state = state.copyWith(imageUrls: photos);
  }

  void setPrice(int price) =>
      state = state.copyWith(price: price < 0 ? 0 : price);

  void increase() => setPrice(state.price + SellDraft.priceStep);

  void decrease() {
    if (state.price - SellDraft.priceStep >= SellDraft.priceStep) {
      setPrice(state.price - SellDraft.priceStep);
    }
  }
}

/// Thể loại để chọn khi đăng.
@riverpod
Future<List<SellCategory>> sellCategories(Ref ref) =>
    ref.watch(sellRepositoryProvider).listCategories();

/// Giá gợi ý theo tên sách + tình trạng đang chọn.
@riverpod
Future<PriceSuggestion?> priceSuggestion(Ref ref) {
  final (title, condition) = ref.watch(
    sellFormProvider.select((d) => (d.title, d.condition)),
  );
  return ref.watch(sellRepositoryProvider).suggestPrice(title, condition);
}

/// Gửi tin đăng. `state` loading → nút "Đăng" bị khoá.
@riverpod
class SubmitListing extends _$SubmitListing {
  @override
  FutureOr<void> build() {}

  Future<bool> submit() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(sellRepositoryProvider)
          .createListing(ref.read(sellFormProvider));
      ref.invalidate(sellFormProvider);
    });
    return !state.hasError;
  }
}
