import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/admin_kit.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Duyệt tin đăng của shop chưa đủ uy tín (SRS 4.1): danh sách bên trái, chi tiết + quyết định bên phải.
class ListingReviewScreen extends ConsumerStatefulWidget {
  const ListingReviewScreen({super.key});

  @override
  ConsumerState<ListingReviewScreen> createState() =>
      _ListingReviewScreenState();
}

class _ListingReviewScreenState extends ConsumerState<ListingReviewScreen> {
  String? _selectedId;

  Future<void> _review(Listing l, {required bool approve}) async {
    final l10n = context.l10n;
    String? reason;
    if (!approve) {
      reason = await showCancelSheet(
        context,
        l10n.listingRejectReasons,
        title: l10n.rejectReasonTitle,
      );
      if (reason == null) return;
    }
    await ref.read(adminActionsProvider.notifier).run(
      (r) => r.reviewListing(l.id, approve: approve, reason: reason),
      [DataArea.listings],
    );
    if (!mounted) return;
    final error = ref.read(adminActionsProvider).error;
    if (error != null) {
      showErrorSnack(context, error);
    } else {
      setState(() => _selectedId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final list = ref.watch(pendingListingsProvider);
    final busy = ref.watch(adminActionsProvider).isLoading;
    final count = list.value?.length;

    return AppPage(
      title: l10n.navListingReview,
      subtitle: count == null || count == 0 ? null : l10n.adminPendingN(count),
      showBack: false,
      onRefresh: () => ref.refresh(pendingListingsProvider.future),
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(pendingListingsProvider),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.task_alt_rounded,
                title: l10n.nothingToDo,
              );
            }
            final selected =
                items.where((l) => l.id == _selectedId).firstOrNull ??
                items.first;
            return LayoutBuilder(
              builder: (context, box) {
                final table = _ListingTable(
                  items: items,
                  selectedId: selected.id,
                  onSelect: (l) => setState(() => _selectedId = l.id),
                );
                final detail = _Detail(
                  listing: selected,
                  busy: busy,
                  onApprove: () => _review(selected, approve: true),
                  onReject: () => _review(selected, approve: false),
                );
                if (box.maxWidth < 900) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      table,
                      const SizedBox(height: AppSpacing.md),
                      detail,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 11, child: table),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 9, child: detail),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const _ReviewedListings(),
      ],
    );
  }
}

/// Tin đã xử lý gần đây kèm người duyệt và thời gian duyệt (SRS 8.1).
class _ReviewedListings extends ConsumerWidget {
  const _ReviewedListings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final items =
        ref.watch(reviewedListingsProvider).value ?? const <Listing>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.admReviewedListingsTitle,
          style: context.textStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: InfoPanel(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final (i, l) in items.take(10).indexed) ...[
                  if (i > 0) Divider(height: 1, indent: 16, color: c.separator),
                  ListTile(
                    title: Text(
                      l.book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      l.status == ListingStatus.rejected
                          ? l10n.admRejectedBy(
                              l.reviewedBy ?? '',
                              formatDateTime(l.reviewedAt ?? l.createdAt),
                            )
                          : l10n.admApprovedBy(
                              l.reviewedBy ?? '',
                              formatDateTime(l.reviewedAt ?? l.createdAt),
                            ),
                    ),
                    trailing: StatusPill(
                      l.status.label(l10n),
                      tone: l.status.tone,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ListingTable extends StatelessWidget {
  const _ListingTable({
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Listing> items;
  final String selectedId;
  final ValueChanged<Listing> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final head = context.textStyles.labelMedium?.copyWith(
      color: AdminPalette.faint,
      fontWeight: FontWeight.w600,
    );
    Widget cell(int flex, Widget child) => Expanded(flex: flex, child: child);

    return LayoutBuilder(
      builder: (context, box) {
        // Điện thoại: bỏ cột Shop / Tình trạng (shop xuống dòng dưới tên sách) để không bị bóp chữ.
        final wide = box.maxWidth >= 560;
        return AdminCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    cell(5, Text(l10n.adminColBook, style: head)),
                    if (wide) cell(3, Text(l10n.adminColShop, style: head)),
                    cell(2, Text(l10n.adminColPrice, style: head)),
                    if (wide)
                      cell(2, Text(l10n.adminColCondition, style: head)),
                  ],
                ),
              ),
              const Divider(height: 1, color: AdminPalette.line),
              for (final l in items)
                InkWell(
                  onTap: () => onSelect(l),
                  child: Container(
                    color: l.id == selectedId
                        ? AdminPalette.selected
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        cell(
                          5,
                          Row(
                            children: [
                              BookPoster(
                                title: l.book.title,
                                author: l.book.author,
                                coverUrl: l.book.coverUrl,
                                seed: l.book.id,
                                width: 30,
                                shadow: false,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.book.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.textStyles.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      wide
                                          ? l.book.author
                                          : '${l.book.author} · ${l.shop.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.textStyles.bodySmall
                                          ?.copyWith(color: AdminPalette.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (wide)
                          cell(
                            3,
                            Text(
                              l.shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        cell(2, Text(formatVnd(l.price))),
                        if (wide)
                          cell(
                            2,
                            Align(
                              alignment: Alignment.centerLeft,
                              child: StatusPill(
                                l.book.condition.label(l10n),
                                tone: l.book.condition.tone,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Detail extends StatefulWidget {
  const _Detail({
    required this.listing,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final Listing listing;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  // Danh sách kiểm tra chỉ để người duyệt tự đối chiếu, không chặn việc duyệt.
  final _checked = <int>{};

  @override
  void didUpdateWidget(_Detail old) {
    super.didUpdateWidget(old);
    if (old.listing.id != widget.listing.id) _checked.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final l = widget.listing;
    final b = l.book;
    final text = context.textStyles;

    Widget check(int i, String label) => InkWell(
      onTap: () => setState(() {
        if (!_checked.add(i)) _checked.remove(i);
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(
              _checked.contains(i)
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: _checked.contains(i)
                  ? AdminPalette.ink
                  : AdminPalette.faint,
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(label, style: text.bodyMedium)),
          ],
        ),
      ),
    );

    return AdminCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookPoster(
                title: b.title,
                author: b.author,
                coverUrl: b.coverUrl,
                seed: b.id,
                width: 92,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      style: text.headlineSmall?.copyWith(
                        fontFamily: AppFonts.serif,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        b.author,
                        ?b.publisher,
                        if (b.publishYear != null) '${b.publishYear}',
                      ].join(' · '),
                      style: text.bodyMedium?.copyWith(
                        color: AdminPalette.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatVnd(l.price),
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        StatusPill(
                          b.condition.label(l10n),
                          tone: b.condition.tone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l.shop.name} · ${l.shop.ratingAvg.toStringAsFixed(1)}★ (${l.shop.ratingCount})',
                      style: text.bodySmall?.copyWith(
                        color: AdminPalette.muted,
                      ),
                    ),
                    Text(
                      '${l10n.adminSubmitted}: ${formatDateTime(l.createdAt)}',
                      style: text.bodySmall?.copyWith(
                        color: AdminPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (b.description != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.adminSellerDesc,
              style: text.labelMedium?.copyWith(
                color: AdminPalette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                border: Border.all(color: AdminPalette.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(b.description!, style: text.bodyMedium),
            ),
          ],
          if (b.images.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.adminPhotos(b.images.length),
              style: text.labelMedium?.copyWith(
                color: AdminPalette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            PhotoStrip(urls: [for (final i in b.images) i.url]),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.adminQuickCheck,
            style: text.labelMedium?.copyWith(
              color: AdminPalette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          check(0, l10n.adminCheckPhoto),
          check(1, l10n.adminCheckCondition),
          check(2, l10n.adminCheckPrice),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              FilledButton(
                onPressed: widget.busy ? null : widget.onApprove,
                child: Text(l10n.approve),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminPalette.bad,
                  side: const BorderSide(color: AdminPalette.bad),
                ),
                onPressed: widget.busy ? null : widget.onReject,
                child: Text(l10n.reject),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
