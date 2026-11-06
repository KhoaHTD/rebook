import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';
import 'package:book_marketplace/features/staff/presentation/providers/staff_providers.dart';
import 'package:book_marketplace/shared/domain/incident.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Sự cố kho (Staff khai báo, Admin duyệt) và kiểm định lại lô bị trả về kho.
class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final isAdmin = ref.watch(currentUserProvider)?.role == AuthRole.admin;
    final busy = ref.watch(staffActionsProvider).isLoading;
    final lots = ref.watch(inspectingLotsProvider);
    final incidents = ref.watch(warehouseIncidentsProvider);
    final actions = ref.read(staffActionsProvider.notifier);

    void after([String? done]) {
      if (!context.mounted) return;
      final error = ref.read(staffActionsProvider).error;
      if (error != null) {
        showErrorSnack(context, error);
      } else if (done != null) {
        showInfoSnack(context, done);
      }
    }

    Future<void> reinspect(InspectingLot l, bool passed) async {
      final report = await showTextSheet(
        context,
        title: passed ? l10n.stfReinspectPass : l10n.stfReinspectFail,
        label: l10n.stfReinspectReport,
        lines: 3,
        rule: Rules.reason,
      );
      if (report == null) return;
      await actions.reinspect(l.lotId, passed: passed, report: report);
      after(l10n.stfReinspected);
    }

    Future<void> approve(WarehouseIncident i) async {
      var percent = 100;
      if (i.type == IncidentType.damaged) {
        final v = await showTextSheet(
          context,
          title: l10n.stfApproveIncident,
          label: l10n.stfSellerPercent,
          rule: Rules.percent,
        );
        if (v == null) return;
        final n = int.tryParse(v.trim());
        if (n == null || n < 0 || n > 100) {
          if (context.mounted) showInfoSnack(context, l10n.stfSellerPercent);
          return;
        }
        percent = n;
      } else if (!await confirmDialog(context, l10n.stfApproveIncident)) {
        return;
      }
      await actions.approveIncident(i.id, sellerPercent: percent);
      after(l10n.stfIncidentDecided);
    }

    Future<void> reject(WarehouseIncident i) async {
      final reason = await showTextSheet(
        context,
        title: l10n.stfRejectIncident,
        label: l10n.decisionNote,
        lines: 3,
        rule: Rules.reason,
      );
      if (reason == null) return;
      await actions.rejectIncident(i.id, reason);
      after(l10n.stfIncidentDecided);
    }

    Widget heading(String t) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(t, style: context.textStyles.titleMedium),
    );

    return AppPage(
      title: l10n.stfNavIncidents,
      showBack: false,
      onRefresh: () async {
        ref.invalidate(inspectingLotsProvider);
        ref.invalidate(warehouseIncidentsProvider);
      },
      children: [
        heading(l10n.stfInspectingTitle),
        AsyncValueView(
          value: lots,
          onRetry: () => ref.invalidate(inspectingLotsProvider),
          data: (list) => list.isEmpty
              ? EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: l10n.nothingToDo,
                )
              : InfoPanel(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      for (final (i, l) in list.indexed) ...[
                        if (i > 0) Divider(height: 1, color: c.separator),
                        ListTile(
                          title: Text(l.bookTitle),
                          subtitle: _TileBody(
                            text: [
                              if (l.consignmentCode != null) l.consignmentCode!,
                              if (l.hammerPrice != null)
                                formatVnd(l.hammerPrice!),
                              if (l.closedAt != null) formatDate(l.closedAt!),
                            ].join(' · '),
                            action: Wrap(
                              spacing: AppSpacing.sm,
                              children: [
                                OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => reinspect(l, false),
                                  child: Text(l10n.stfReinspectFail),
                                ),
                                FilledButton(
                                  onPressed: busy
                                      ? null
                                      : () => reinspect(l, true),
                                  child: Text(l10n.stfReinspectPass),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
        heading(l10n.stfIncidentsTitle),
        AsyncValueView(
          value: incidents,
          onRetry: () => ref.invalidate(warehouseIncidentsProvider),
          data: (list) => list.isEmpty
              ? EmptyState(
                  icon: Icons.report_problem_outlined,
                  title: l10n.nothingToDo,
                )
              : InfoPanel(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      for (final (i, x) in list.indexed) ...[
                        if (i > 0) Divider(height: 1, color: c.separator),
                        ListTile(
                          title: Text(x.bookTitle),
                          subtitle: _TileBody(
                            text: [
                              x.type == IncidentType.lost
                                  ? l10n.stfIncidentLost
                                  : l10n.stfIncidentDamaged,
                              x.description,
                              if (x.sellerPercent != null)
                                '${x.sellerPercent}%',
                              if (x.decisionNote != null) x.decisionNote!,
                            ].join(' · '),
                            action: x.status == IncidentStatus.pending
                                ? (isAdmin
                                      ? Wrap(
                                          spacing: AppSpacing.sm,
                                          children: [
                                            OutlinedButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => reject(x),
                                              child: Text(
                                                l10n.stfRejectIncident,
                                              ),
                                            ),
                                            FilledButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => approve(x),
                                              child: Text(
                                                l10n.stfApproveIncident,
                                              ),
                                            ),
                                          ],
                                        )
                                      : StatusPill(
                                          l10n.stfIncidentPending,
                                          tone: StatusTone.warning,
                                        ))
                                : StatusPill(
                                    x.status == IncidentStatus.approved
                                        ? l10n.stfIncidentApproved
                                        : l10n.stfIncidentRejected,
                                    tone: x.status == IncidentStatus.approved
                                        ? StatusTone.success
                                        : StatusTone.danger,
                                  ),
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

/// Chữ mô tả và hàng nút / nhãn bên dưới (không ép sang cột phải, vì màn điện thoại hẹp).
class _TileBody extends StatelessWidget {
  const _TileBody({required this.text, required this.action});

  final String text;
  final Widget action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text),
      const SizedBox(height: AppSpacing.sm),
      action,
    ],
  );
}
