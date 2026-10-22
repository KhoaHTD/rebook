import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/sell/domain/sell_draft.dart';
import 'package:book_marketplace/features/sell/presentation/providers/sell_providers.dart';
import 'package:book_marketplace/shared/domain/book.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_condition_badge.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/grouped_section.dart';

/// Sheet Đăng bán: ảnh thật, thông tin sách, tình trạng, giá (có gợi ý), số tiền thực nhận.
class SellScreen extends ConsumerWidget {
  const SellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final draft = ref.watch(sellFormProvider);
    final submitting = ref.watch(submitListingProvider).isLoading;

    Future<void> submit() async {
      if (!draft.isValid) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.sellMissingInfo)));
        return;
      }
      final ok = await ref.read(submitListingProvider.notifier).submit();
      if (!context.mounted) return;
      final error = ref.read(submitListingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? l10n.listingSubmitted : errorMessage(context, error!),
          ),
        ),
      );
      if (ok) _close(context);
    }

    return Scaffold(
      backgroundColor: colors.groupedBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            MaxWidthBox(
              maxWidth: 640,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  76,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                children: [
                  _PhotoStrip(photos: draft.imageUrls),
                  const SizedBox(height: 22),
                  _BookInfo(draft: draft),
                  const SizedBox(height: 22),
                  _ConditionPicker(selected: draft.condition),
                  const SizedBox(height: 22),
                  _PriceEditor(draft: draft),
                  const SizedBox(height: 22),
                  GroupedSection(
                    footer: l10n.sellEscrowNote,
                    children: [
                      GroupedRow(
                        title: l10n.sellPrice,
                        trailingText: formatVnd(draft.price),
                      ),
                      GroupedRow(
                        title: l10n.platformFee(SellDraft.feePercent),
                        trailingText: '−${formatVnd(draft.fee)}',
                      ),
                      GroupedRow(
                        title: l10n.youReceive,
                        emphasized: true,
                        trailing: Text(
                          formatVnd(draft.net),
                          style: context.textStyles.titleLarge?.copyWith(
                            color: colors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  GroupedSection(
                    children: [
                      GroupedRow(
                        minHeight: 60,
                        leading: RowIcon(
                          icon: Icons.gavel_rounded,
                          color: colors.strongSurface,
                        ),
                        title: l10n.consignInstead,
                        subtitle: l10n.consignInsteadHint,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Mép trên mờ dần để nội dung cuộn không chồng lên thanh tiêu đề
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 96,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.6, 1],
                      colors: [
                        colors.groupedBackground,
                        colors.groupedBackground.withValues(alpha: 0.95),
                        colors.groupedBackground.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Thanh trên cùng: huỷ · tiêu đề · Đăng
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: MaxWidthBox(
                maxWidth: 640,
                child: Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.close_rounded,
                      tooltip: l10n.cancel,
                      onPressed: () => _close(context),
                    ),
                    Expanded(
                      child: Text(
                        l10n.sellTitle,
                        textAlign: TextAlign.center,
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                    FilledButton(
                      onPressed: submitting ? null : submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, AppSizes.touch),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: Text(l10n.post),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _close(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.home);
}

class _PhotoStrip extends ConsumerWidget {
  const _PhotoStrip({required this.photos});

  final List<String> photos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final hints = [
      l10n.photoFront,
      l10n.photoBack,
      l10n.photoSpine,
      l10n.photoDamage,
    ];
    // Luôn chừa một ô trống để thêm ảnh (tối đa SellDraft.maxPhotos).
    final count = (photos.length + 1).clamp(hints.length, SellDraft.maxPhotos);

    // Chưa có package chụp / chọn ảnh trong allowlist (image_picker):
    // tạm dán link ảnh đã tải lên kho ảnh (backend chỉ lưu URL).
    Future<void> edit(int i) async {
      final url = await _askPhotoUrl(
        context,
        i < photos.length ? photos[i] : '',
      );
      if (url != null) ref.read(sellFormProvider.notifier).setPhoto(i, url);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final url = i < photos.length ? photos[i] : null;
              final hint = i < hints.length ? hints[i] : l10n.photoMore;
              return SizedBox(
                width: 96,
                child: Material(
                  color: colors.groupedCell,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  child: InkWell(
                    onTap: () => edit(i),
                    child: url != null
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Icon(
                              Icons.broken_image_outlined,
                              color: colors.caution,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: context.colors.primary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hint,
                                textAlign: TextAlign.center,
                                style: context.textStyles.labelMedium?.copyWith(
                                  color: context.colors.primary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            l10n.photoHintCount(photos.length, SellDraft.minPhotos),
            style: context.textStyles.bodySmall?.copyWith(
              color: photos.length >= SellDraft.minPhotos
                  ? colors.labelTertiary
                  : colors.caution,
            ),
          ),
        ),
      ],
    );
  }
}

Future<String?> _askPhotoUrl(BuildContext context, String initial) {
  final controller = TextEditingController(text: initial);
  final l10n = context.l10n;
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.photoUrlTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(hintText: l10n.photoUrlHint),
      ),
      actions: [
        if (initial.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: Text(l10n.remove),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

class _BookInfo extends ConsumerWidget {
  const _BookInfo({required this.draft});

  final SellDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final form = ref.read(sellFormProvider.notifier);
    return GroupedSection(
      header: l10n.bookInfo,
      children: [
        _InlineField(
          label: l10n.bookTitle,
          initial: draft.title,
          onChanged: form.setTitle,
        ),
        _InlineField(
          label: l10n.bookAuthor,
          initial: draft.author,
          onChanged: form.setAuthor,
        ),
        GroupedRow(
          title: l10n.category,
          trailingText: draft.category?.name ?? l10n.chooseCategory,
          trailing: Icon(
            Icons.unfold_more_rounded,
            size: 18,
            color: context.appColors.labelTertiary,
          ),
          onTap: () => _pickCategory(context, ref),
        ),
        _InlineField(
          label: l10n.publisher,
          initial: draft.publisher,
          onChanged: form.setPublisher,
        ),
        _InlineField(
          label: l10n.publishYear,
          initial: draft.publishYear?.toString() ?? '',
          onChanged: form.setYear,
          numeric: true,
        ),
        _InlineField(
          label: l10n.weightGram,
          initial: '${draft.weightGram}',
          onChanged: form.setWeight,
          numeric: true,
        ),
      ],
    );
  }

  Future<void> _pickCategory(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<SellCategory>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (context, ref, _) => AsyncValueView(
          value: ref.watch(sellCategoriesProvider),
          onRetry: () => ref.invalidate(sellCategoriesProvider),
          data: (cats) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            children: [
              GroupedSection(
                header: context.l10n.category,
                children: [
                  for (final c in cats)
                    GroupedRow(
                      title: c.name,
                      trailing: c.id == draft.category?.id
                          ? Icon(
                              Icons.check_rounded,
                              color: context.colors.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(c),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) ref.read(sellFormProvider.notifier).setCategory(picked);
  }
}

/// Dòng "Nhãn ............ giá trị" có thể gõ trực tiếp ở bên phải.
class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.label,
    required this.initial,
    required this.onChanged,
    this.numeric = false,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Text(label, style: context.textStyles.bodyLarge),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextFormField(
              initialValue: initial,
              textAlign: TextAlign.end,
              keyboardType: numeric ? TextInputType.number : TextInputType.text,
              inputFormatters: numeric
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.appColors.labelTertiary,
              ),
              decoration: InputDecoration(
                hintText: label,
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionPicker extends ConsumerWidget {
  const _ConditionPicker({required this.selected});

  final BookCondition selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GroupedSection(
      header: context.l10n.condition,
      children: [
        for (final c in BookCondition.selectable)
          Semantics(
            selected: c == selected,
            child: GroupedRow(
              title: conditionLabel(context, c),
              subtitle: conditionDescription(context, c),
              trailing: c == selected
                  ? Icon(Icons.check_rounded, color: context.colors.primary)
                  : null,
              onTap: () => ref.read(sellFormProvider.notifier).setCondition(c),
            ),
          ),
      ],
    );
  }
}

class _PriceEditor extends ConsumerWidget {
  const _PriceEditor({required this.draft});

  final SellDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final form = ref.read(sellFormProvider.notifier);
    final suggestion = ref.watch(priceSuggestionProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            6,
          ),
          child: Text(
            l10n.sellPrice,
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.labelTertiary,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.only(left: AppSpacing.md, right: 12),
          decoration: BoxDecoration(
            color: colors.groupedCell,
            borderRadius: AppRadius.group,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  formatVnd(draft.price),
                  style: context.textStyles.headlineSmall,
                ),
              ),
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: colors.fill,
                  borderRadius: AppRadius.pill,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: l10n.decreasePrice(
                        formatVnd(SellDraft.priceStep),
                      ),
                      onPressed: form.decrease,
                      icon: const Icon(Icons.remove_rounded, size: 18),
                    ),
                    SizedBox(
                      height: 18,
                      child: VerticalDivider(color: colors.separator),
                    ),
                    IconButton(
                      tooltip: l10n.increasePrice(
                        formatVnd(SellDraft.priceStep),
                      ),
                      onPressed: form.increase,
                      icon: const Icon(Icons.add_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (suggestion != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              6,
              AppSpacing.md,
              0,
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.priceSuggestion(
                    conditionLabel(context, draft.condition).toLowerCase(),
                    formatVnd(suggestion.low),
                    formatVnd(suggestion.high),
                  ),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.labelTertiary,
                    height: 1.4,
                  ),
                ),
                TextButton(
                  onPressed: () => form.setPrice(suggestion.mid),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 32),
                    textStyle: context.textStyles.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.useSuggested(formatVnd(suggestion.mid))),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
