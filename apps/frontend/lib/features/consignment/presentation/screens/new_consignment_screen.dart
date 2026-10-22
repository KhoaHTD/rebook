import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/consignment/presentation/providers/consignment_providers.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/rules.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_form.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Gửi yêu cầu ký gửi: ảnh, thông tin sách, giá mong muốn, câu chuyện (SRS 6.1).
class NewConsignmentScreen extends ConsumerWidget {
  const NewConsignmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(consignmentCategoriesProvider);
    return AppPage(
      title: context.l10n.newConsignment,
      showBack: true,
      children: [
        AsyncValueView(
          value: categories,
          onRetry: () => ref.invalidate(consignmentCategoriesProvider),
          data: (cats) => Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _Form(categories: cats),
            ),
          ),
        ),
      ],
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.categories});

  final List<Category> categories;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _book = GlobalKey<BookFormState>();
  final _form = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _story = TextEditingController();

  @override
  void dispose() {
    _price.dispose();
    _story.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final a = _book.currentState!.validate();
    final b = _form.currentState!.validate();
    if (!a || !b) return;
    final c = await ref
        .read(consignmentActionsProvider.notifier)
        .create(
          _book.currentState!.draft(),
          int.parse(_price.text),
          _story.text.trim(),
        );
    if (!mounted) return;
    if (c == null) {
      showErrorSnack(context, ref.read(consignmentActionsProvider).error!);
      return;
    }
    showInfoSnack(context, context.l10n.consignmentSent);
    context.go(Routes.consignment(c.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = ref.watch(consignmentActionsProvider).isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookForm(
          key: _book,
          categories: widget.categories,
          photoFolder: 'consignments',
        ),
        const SizedBox(height: AppSpacing.md),
        Form(
          key: _form,
          child: InfoPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.expectedPrice,
                    helperText: l10n.expectedPriceHint(
                      formatVnd(consignmentMinExpectedPrice),
                    ),
                  ),
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ? l10n.invalidNumber : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _story,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: l10n.bookStory,
                    hintText: l10n.bookStoryHint,
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
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
            child: Text(l10n.submitConsignment),
          ),
        ),
      ],
    );
  }
}
