import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/consignment/presentation/providers/consignment_providers.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/rules.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/inspection_view.dart';
import 'package:book_marketplace/shared/widgets/money_summary.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Một yêu cầu ký gửi — phần hành động đổi theo từng bước:
/// sơ duyệt → đặt lịch → mã hẹn → kiểm định + quyết định giá → thành lô → kết quả (SRS 6.1, 6.2, 6.6).
class ConsignmentDetailScreen extends ConsumerWidget {
  const ConsignmentDetailScreen({super.key, required this.consignmentId});

  final String consignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(consignmentDetailProvider(consignmentId));
    final compact = context.windowSize.isCompact;
    return AppPage(
      title: c.value?.book.title ?? context.l10n.myConsignments,
      showBack: true,
      onRefresh: () =>
          ref.refresh(consignmentDetailProvider(consignmentId).future),
      children: [
        AsyncValueView(
          value: c,
          onRetry: () =>
              ref.invalidate(consignmentDetailProvider(consignmentId)),
          data: (c) {
            final poster = BookPoster(
              title: c.book.title,
              author: c.book.author,
              coverUrl: c.book.coverUrl,
              seed: c.book.id,
              width: compact ? 180 : 240,
            );
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Summary(c: c),
                ..._stepFor(context, c),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: poster),
                  const SizedBox(height: AppSpacing.xl),
                  info,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                poster,
                const SizedBox(width: 56),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: info,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _stepFor(BuildContext context, Consignment c) {
    final l10n = context.l10n;
    return switch (c.status) {
      ConsignmentStatus.preRejected when c.rejectReason != null => [
        _Panel(
          title: l10n.csPreRejected,
          child: Text(l10n.rejectedBecause(c.rejectReason!)),
        ),
      ],
      ConsignmentStatus.preApproved => [_SlotPicker(c: c)],
      ConsignmentStatus.appointmentBooked => [_Appointment(c: c)],
      ConsignmentStatus.inspected when c.inspection != null => [
        _Decision(c: c),
      ],
      ConsignmentStatus.inspectionFailed when c.inspection != null => [
        _Panel(
          title: l10n.inspectionReport,
          child: InspectionView(inspection: c.inspection!),
        ),
      ],
      ConsignmentStatus.accepted => [_AsLot(c: c)],
      _ => const [],
    };
  }
}

/// Khối nội dung một bước: tiêu đề + nền xám nhạt.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg),
    child: InfoPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.c});

  final Consignment c;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final compact = context.windowSize.isCompact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact) ...[
          Text(c.book.title, style: context.textStyles.displaySmall),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          c.book.author,
          style: context.textStyles.titleLarge?.copyWith(
            color: colors.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusPill(c.status.label(l10n), tone: c.status.tone),
            StatusPill(
              c.book.condition.label(l10n),
              tone: c.book.condition.tone,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.submittedAt(formatDate(c.createdAt)),
          style: context.textStyles.bodySmall,
        ),
        if (c.warehouseCode != null)
          Text(
            l10n.shelf(c.warehouseCode!),
            style: context.textStyles.bodySmall,
          ),
        const SizedBox(height: AppSpacing.sm),
        MoneyLine(l10n.expectedPrice, c.expectedPrice),
        const SizedBox(height: AppSpacing.md),
        Text(c.story, style: context.textStyles.bodyLarge),
      ],
    );
  }
}

class _SlotPicker extends ConsumerStatefulWidget {
  const _SlotPicker({required this.c});

  final Consignment c;

  @override
  ConsumerState<_SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends ConsumerState<_SlotPicker> {
  DateTime? _picked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slots = ref.watch(appointmentSlotsProvider(widget.c.id));
    final busy = ref.watch(consignmentActionsProvider).isLoading;
    return _Panel(
      title: l10n.pickSlot,
      child: AsyncValueView(
        value: slots,
        onRetry: () => ref.invalidate(appointmentSlotsProvider(widget.c.id)),
        data: (list) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final s in list)
                  ChoiceChip(
                    label: Text(formatShortDateTime(s.startAt)),
                    selected: _picked == s.startAt,
                    onSelected: s.available
                        ? (_) => setState(() => _picked = s.startAt)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _picked == null || busy
                  ? null
                  : () async {
                      final r = await ref
                          .read(consignmentActionsProvider.notifier)
                          .book(widget.c.id, _picked!);
                      if (r == null && context.mounted) {
                        showErrorSnack(
                          context,
                          ref.read(consignmentActionsProvider).error!,
                        );
                      }
                    },
              child: Text(l10n.bookSlot),
            ),
          ],
        ),
      ),
    );
  }
}

class _Appointment extends StatelessWidget {
  const _Appointment({required this.c});

  final Consignment c;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Panel(
      title: l10n.appointmentCode,
      child: Column(
        children: [
          Text(
            c.appointmentCode ?? '',
            style: context.textStyles.displaySmall?.copyWith(letterSpacing: 6),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (c.appointmentAt != null)
            Text(l10n.appointmentAt(formatDateTime(c.appointmentAt!))),
          if (c.appointmentExpiresAt != null)
            Text(
              l10n.appointmentExpires(formatDateTime(c.appointmentExpiresAt!)),
              style: context.textStyles.bodySmall,
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.showCodeAtWarehouse,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Kết quả kiểm định + quyết định của người gửi: chấp nhận / đề nghị giá sàn / rút (SRS 6.2).
class _Decision extends ConsumerStatefulWidget {
  const _Decision({required this.c});

  final Consignment c;

  @override
  ConsumerState<_Decision> createState() => _DecisionState();
}

class _DecisionState extends ConsumerState<_Decision> {
  var _agreed = false;

  Future<void> _decide(SellerDecision d, {int? reserve}) async {
    final r = await ref
        .read(consignmentActionsProvider.notifier)
        .decide(widget.c.id, d, counterReserve: reserve);
    if (!mounted) return;
    if (r == null) {
      showErrorSnack(context, ref.read(consignmentActionsProvider).error!);
    } else if (d == SellerDecision.accept) {
      showInfoSnack(context, context.l10n.lotCreated);
    }
  }

  Future<void> _counter() async {
    final l10n = context.l10n;
    final inspection = widget.c.inspection!;
    final low = inspection.estimateLow;
    final value = await showAmountSheet(
      context,
      title: l10n.counterReserve,
      label: l10n.proposedReserve,
      hint: low == null ? null : l10n.counterReserveHint(formatVnd(low)),
      initial: inspection.proposedReserve,
      max: low,
    );
    if (value != null) await _decide(SellerDecision.counter, reserve: value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = ref.watch(consignmentActionsProvider).isLoading;
    final inspection = widget.c.inspection!;
    const fees = FeeConfig();
    // Đã đề nghị giá sàn → chờ ReBook phản hồi, không cho quyết định lại.
    final waiting = inspection.sellerDecision == SellerDecision.counter;
    return _Panel(
      title: l10n.inspectionReport,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectionView(inspection: inspection),
          if (!waiting) ...[
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              title: Text(
                l10n.agreeConsignTerms(fees.sellerCommissionPercent.round()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _agreed && !busy
                  ? () => _decide(SellerDecision.accept)
                  : null,
              child: Text(l10n.acceptProposal),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: _agreed && !busy ? _counter : null,
              child: Text(l10n.counterReserve),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (await confirmDialog(context, l10n.withdrawConfirm)) {
                        await _decide(SellerDecision.withdraw);
                      }
                    },
              child: Text(l10n.withdrawConsignment),
            ),
          ],
        ],
      ),
    );
  }
}

/// Đã thành lô: trạng thái lô, giá búa, tiền nhận; không bán được → chọn hướng xử lý (SRS 6.6).
class _AsLot extends ConsumerWidget {
  const _AsLot({required this.c});

  final Consignment c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final busy = ref.watch(consignmentActionsProvider).isLoading;
    final status = c.lotStatus;

    Future<void> choose(UnsoldChoice choice) async {
      int? amount;
      if (choice != UnsoldChoice.returnToSeller) {
        final next = choice == UnsoldChoice.nextSession;
        amount = await showAmountSheet(
          context,
          title: next ? l10n.unsoldNext : l10n.unsoldFixed,
          label: next ? l10n.newReserve : l10n.fixedPrice,
        );
        if (amount == null) return;
      } else if (!context.mounted ||
          !await confirmDialog(context, l10n.unsoldReturn)) {
        return;
      }
      final r = await ref
          .read(consignmentActionsProvider.notifier)
          .afterUnsold(
            c.id,
            choice,
            newReserve: choice == UnsoldChoice.nextSession ? amount : null,
            fixedPrice: choice == UnsoldChoice.fixedPrice ? amount : null,
          );
      if (!context.mounted) return;
      if (r == null) {
        showErrorSnack(context, ref.read(consignmentActionsProvider).error!);
      } else {
        showInfoSnack(context, l10n.choiceSaved);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          title: l10n.csAccepted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status != null)
                StatusPill(status.label(l10n), tone: status.tone),
              if (c.hammerPrice != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.soldFor(formatVnd(c.hammerPrice!)),
                  style: context.textStyles.titleLarge,
                ),
              ],
              if (c.payout != null) MoneyLine(l10n.payout, c.payout!),
              if (c.lotId != null) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => context.go(Routes.lot(c.lotId!)),
                  child: Text(l10n.viewLot),
                ),
              ],
            ],
          ),
        ),
        if (status == LotStatus.unsold)
          _Panel(
            title: l10n.unsoldTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => choose(UnsoldChoice.nextSession),
                  child: Text(l10n.unsoldNext),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => choose(UnsoldChoice.fixedPrice),
                  child: Text(l10n.unsoldFixed),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => choose(UnsoldChoice.returnToSeller),
                  child: Text(l10n.unsoldReturn),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
