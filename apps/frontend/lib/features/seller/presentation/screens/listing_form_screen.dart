import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/seller/presentation/providers/seller_providers.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_form.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Đăng mới / sửa một tin bán giá cố định: ≥ 3 ảnh, thông tin sách, tình trạng, giá, tồn kho (SRS 4.1).
class ListingFormScreen extends ConsumerWidget {
  const ListingFormScreen({super.key, this.listingId});

  final String? listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(sellerCategoriesProvider);
    final AsyncValue<Listing?> existing = listingId == null
        ? const AsyncData(null)
        : ref.watch(sellerListingProvider(listingId!));
    return AppPage(
      title: listingId == null ? l10n.newListing : l10n.editListing,
      showBack: true,
      children: [
        AsyncValueView(
          value: categories,
          onRetry: () => ref.invalidate(sellerCategoriesProvider),
          data: (cats) => AsyncValueView(
            value: existing,
            onRetry: () => ref.invalidate(sellerListingProvider(listingId!)),
            data: (l) => Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _Form(categories: cats, initial: l),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.categories, this.initial});

  final List<Category> categories;
  final Listing? initial;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _book = GlobalKey<BookFormState>();
  final _sale = GlobalKey<FormState>();
  late final _price = TextEditingController(
    text: widget.initial?.price.toString(),
  );
  late final _stock = TextEditingController(
    text: widget.initial?.stock.toString() ?? '1',
  );

  @override
  void dispose() {
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bookOk = _book.currentState!.validate();
    final saleOk = _sale.currentState!.validate();
    if (!bookOk || !saleOk) return;
    final saved = await ref
        .read(sellerActionsProvider.notifier)
        .saveListing(
          widget.initial?.id,
          _book.currentState!.draft(),
          price: int.parse(_price.text),
          stock: int.parse(_stock.text),
        );
    if (!mounted) return;
    if (saved == null) {
      showErrorSnack(context, ref.read(sellerActionsProvider).error!);
      return;
    }
    showInfoSnack(
      context,
      saved.status == ListingStatus.pendingReview
          ? context.l10n.listingSavedReview
          : context.l10n.listingSaved,
    );
    context.go(Routes.sellerListings);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = ref.watch(sellerActionsProvider).isLoading;
    final initial = widget.initial;
    String? number(String? v, {int min = 1}) {
      final n = int.tryParse(v ?? '');
      return n == null || n < min ? l10n.invalidNumber : null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (initial != null) ...[
          Row(
            children: [
              StatusPill(initial.status.label(l10n), tone: initial.status.tone),
              if (initial.rejectReason != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.rejectReason(initial.rejectReason!),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        BookForm(
          key: _book,
          categories: widget.categories,
          photoFolder: 'listings',
          initial: initial?.book,
        ),
        const SizedBox(height: AppSpacing.md),
        Form(
          key: _sale,
          child: InfoPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.price),
                    validator: (v) => number(v, min: 1000),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.stock),
                    validator: (v) => number(v, min: 0),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: busy ? null : _submit,
            child: Text(l10n.save),
          ),
        ),
      ],
    );
  }
}
