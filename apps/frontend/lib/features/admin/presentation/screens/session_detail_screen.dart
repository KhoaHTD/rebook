import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/admin/presentation/screens/session_edit_screen.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Cùng một địa chỉ `/sessions/:id`: Admin vào màn sửa phiên, Staff vào màn chi tiết chỉ xem.
class SessionPage extends ConsumerWidget {
  const SessionPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(currentUserProvider)?.role == AuthRole.admin;
    return isAdmin
        ? SessionEditScreen(sessionId: sessionId)
        : SessionDetailScreen(sessionId: sessionId);
  }
}

/// Chi tiết một phiên đấu giá, chỉ xem (Staff): thời gian, số người đăng ký, tiền cọc và từng lô sách.
/// Admin sửa phiên ở màn riêng ([SessionEditScreen]).
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(adminSessionProvider(sessionId));
    return AppPage(
      title: data.value?.$1.title ?? '',
      showBack: true,
      onRefresh: () => ref.refresh(adminSessionProvider(sessionId).future),
      children: [
        AsyncValueView(
          value: data,
          onRetry: () => ref.invalidate(adminSessionProvider(sessionId)),
          data: (d) {
            final (s, lots) = d;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoPanel(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusPill(s.status.label(l10n), tone: s.status.tone),
                          if (s.isLive)
                            FilledButton.tonal(
                              onPressed: () =>
                                  context.go(AdminRoutes.monitor(s.id)),
                              child: Text(l10n.monitor),
                            ),
                        ],
                      ),
                      if (s.description != null &&
                          s.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          s.description!,
                          style: context.textStyles.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _Fact(l10n.sessionStart, formatDateTime(s.startAt)),
                      _Fact(
                        l10n.sessionDeadline,
                        formatDateTime(s.registrationDeadline),
                      ),
                      _Fact(
                        l10n.registeredCount(s.registeredCount),
                        '${l10n.minParticipants}: ${s.minParticipants}',
                      ),
                      _Fact(l10n.depositAmount, formatVnd(s.depositAmount)),
                      _Fact(
                        l10n.lotsCount(s.lotCount),
                        '${s.lotDurationSec}s · +${s.softCloseSec}s',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(l10n.lotsInSession),
                const SizedBox(height: AppSpacing.md),
                for (final lot in lots) _LotRow(lot: lot),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(
                color: c.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.textStyles.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LotRow extends StatelessWidget {
  const _LotRow({required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final sold = lot.hammerPrice;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InfoPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            BookPoster(
              title: lot.book.title,
              author: '',
              coverUrl: lot.book.coverUrl,
              seed: lot.book.id,
              width: 52,
              shadow: false,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${lot.lotNumber} · ${lot.book.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleSmall,
                  ),
                  if (lot.book.author.isNotEmpty)
                    Text(
                      lot.book.author,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: c.secondaryText,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${l10n.startPrice}: ${formatVnd(lot.startPrice)}'
                    '${sold != null ? ' · ${formatVnd(sold)}' : ''}',
                    style: context.textStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusPill(lot.status.label(l10n), tone: lot.status.tone),
          ],
        ),
      ),
    );
  }
}
