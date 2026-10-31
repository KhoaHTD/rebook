import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/shared/widgets/form_widgets.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/staff/presentation/providers/staff_providers.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/inspection_view.dart';
import 'package:book_marketplace/shared/widgets/money_summary.dart';
import 'package:book_marketplace/shared/widgets/photo_picker.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Hồ sơ một yêu cầu ký gửi phía kho; sách đã nhận → lập phiếu kiểm định (SRS 6.2).
class InspectionScreen extends ConsumerWidget {
  const InspectionScreen({super.key, required this.consignmentId});

  final String consignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(staffConsignmentProvider(consignmentId));
    return AppPage(
      title: c.value?.book.title ?? context.l10n.navConsignments,
      showBack: true,
      children: [
        AsyncValueView(
          value: c,
          onRetry: () =>
              ref.invalidate(staffConsignmentProvider(consignmentId)),
          data: (c) {
            final summary = _Summary(c: c);
            final right = c.status == ConsignmentStatus.received
                ? _InspectionForm(c: c)
                : c.inspection != null
                ? InfoPanel(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: InspectionView(inspection: c.inspection!),
                  )
                : const SizedBox.shrink();
            if (context.windowSize == WindowSize.expanded) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 320, child: summary),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(child: right),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summary,
                const SizedBox(height: AppSpacing.lg),
                right,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.c});

  final Consignment c;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: BookPoster(
            title: c.book.title,
            author: c.book.author,
            coverUrl: c.book.coverUrl,
            seed: c.book.id,
            width: 200,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(c.book.author, style: context.textStyles.titleMedium),
        Text(c.sellerName, style: context.textStyles.bodySmall),
        const SizedBox(height: AppSpacing.sm),
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
        const SizedBox(height: AppSpacing.sm),
        MoneyLine(l10n.expectedPrice, c.expectedPrice),
        if (c.warehouseCode != null)
          Text(
            l10n.shelf(c.warehouseCode!),
            style: context.textStyles.bodySmall,
          ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.bookStory, style: context.textStyles.titleSmall),
        Text(c.story, style: context.textStyles.bodyMedium),
        if (c.book.images.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          PhotoStrip(urls: [for (final i in c.book.images) i.url], size: 64),
        ],
      ],
    );
  }
}

class _InspectionForm extends ConsumerStatefulWidget {
  const _InspectionForm({required this.c});

  final Consignment c;

  @override
  ConsumerState<_InspectionForm> createState() => _InspectionFormState();
}

class _InspectionFormState extends ConsumerState<_InspectionForm> {
  var _result = InspectionResult.pass;
  var _checklist = const InspectionChecklist();
  late var _condition = widget.c.book.condition == ConditionGrade.unknown
      ? ConditionGrade.good
      : widget.c.book.condition;
  final _report = TextEditingController();
  final _low = TextEditingController();
  final _high = TextEditingController();
  final _start = TextEditingController();
  final _reserve = TextEditingController();
  var _photos = <String>[];

  @override
  void dispose() {
    for (final c in [_report, _low, _high, _start, _reserve]) {
      c.dispose();
    }
    super.dispose();
  }

  InspectionChecklist _toggle(int i, bool v) {
    final c = _checklist;
    return switch (i) {
      0 => c.copyWith(fullPages: v),
      1 => c.copyWith(correctEdition: v),
      2 => c.copyWith(coverOk: v),
      3 => c.copyWith(spineOk: v),
      4 => c.copyWith(pagesOk: v),
      5 => c.copyWith(noMold: v),
      _ => c.copyWith(hasNotes: v),
    };
  }

  Future<void> _submit() async {
    final pass = _result == InspectionResult.pass;
    final draft = InspectionDraft(
      result: _result,
      checklist: _checklist,
      condition: _condition,
      conditionReport: _report.text.trim(),
      staffImageUrls: _photos,
      estimateLow: pass ? int.tryParse(_low.text) : null,
      estimateHigh: pass ? int.tryParse(_high.text) : null,
      proposedStart: pass ? int.tryParse(_start.text) : null,
      proposedReserve: pass ? int.tryParse(_reserve.text) : null,
    );
    final r = await ref
        .read(staffActionsProvider.notifier)
        .submitInspection(widget.c.id, draft);
    if (!mounted) return;
    if (r == null) {
      showErrorSnack(context, ref.read(staffActionsProvider).error!);
      return;
    }
    showInfoSnack(context, context.l10n.inspectionSent);
    context.go(AdminRoutes.consignments);
  }

  /// Giá sàn đề xuất không vượt mức thấp của ước tính (SRS 6.2).
  bool get _valid {
    if (!Rules.conditionReport.isValid(_report.text) || _photos.isEmpty) {
      return false;
    }
    if (_result == InspectionResult.fail) return true;
    final low = int.tryParse(_low.text);
    final high = int.tryParse(_high.text);
    final start = int.tryParse(_start.text);
    final reserve = int.tryParse(_reserve.text);
    return Rules.estimate.isValid(_low.text) &&
        Rules.estimate.isValid(_high.text) &&
        Rules.startPrice.isValid(_start.text) &&
        Rules.reserve.isValid(_reserve.text) &&
        low != null &&
        high != null &&
        start != null &&
        reserve != null &&
        low <= high &&
        reserve <= low;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = ref.watch(staffActionsProvider).isLoading;
    Widget money(TextEditingController c, String label, InputRule rule) =>
        Expanded(
          child: RuleField(
            controller: c,
            rule: rule,
            label: label,
            bottom: 0,
            onChanged: (_) => setState(() {}),
          ),
        );
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(t, style: context.textStyles.titleSmall),
    );

    return InfoPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.inspectionReport, style: context.textStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<InspectionResult>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: InspectionResult.pass,
                label: Text(l10n.inspectionPass),
              ),
              ButtonSegment(
                value: InspectionResult.fail,
                label: Text(l10n.inspectionFail),
              ),
            ],
            selected: {_result},
            onSelectionChanged: (s) => setState(() => _result = s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (i, (text, value)) in checklistItems(
                l10n,
                _checklist,
              ).indexed)
                FilterChip(
                  label: Text(text),
                  selected: value,
                  onSelected: (v) => setState(() => _checklist = _toggle(i, v)),
                ),
            ],
          ),
          label(l10n.signature),
          SegmentedButton<SignatureStatus>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: SignatureStatus.none,
                label: Text(l10n.signatureNone),
              ),
              ButtonSegment(
                value: SignatureStatus.unverified,
                label: Text(l10n.signatureUnverified),
              ),
              ButtonSegment(
                value: SignatureStatus.verified,
                label: Text(l10n.signatureVerified),
              ),
            ],
            selected: {_checklist.signature},
            onSelectionChanged: (s) => setState(
              () => _checklist = _checklist.copyWith(signature: s.first),
            ),
          ),
          label(l10n.pickCondition),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final g in ConditionGrade.values.where(
                (g) => g != ConditionGrade.unknown,
              ))
                ChoiceChip(
                  label: Text(g.label(l10n)),
                  selected: _condition == g,
                  onSelected: (_) => setState(() => _condition = g),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          RuleField(
            controller: _report,
            rule: Rules.conditionReport,
            label: l10n.conditionReport,
            minLines: 3,
            maxLines: 6,
            showCounter: true,
            onChanged: (_) => setState(() {}),
          ),
          label(l10n.staffPhotos),
          PhotoPickerField(
            folder: 'inspections',
            onChanged: (urls) => setState(() => _photos = urls),
          ),
          if (_result == InspectionResult.pass) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                money(_low, l10n.estimateLow, Rules.estimate),
                const SizedBox(width: AppSpacing.sm),
                money(_high, l10n.estimateHigh, Rules.estimate),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                money(_start, l10n.proposedStart, Rules.startPrice),
                const SizedBox(width: AppSpacing.sm),
                money(_reserve, l10n.proposedReserve, Rules.reserve),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _valid && !busy ? _submit : null,
            child: Text(l10n.submitInspection),
          ),
        ],
      ),
    );
  }
}
