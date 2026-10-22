import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/money_summary.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';

/// Các mục kiểm tra trong phiếu kiểm định, theo thứ tự hiển thị.
List<(String, bool)> checklistItems(
  AppLocalizations l10n,
  InspectionChecklist c,
) => [
  (l10n.checkFullPages, c.fullPages),
  (l10n.checkEdition, c.correctEdition),
  (l10n.checkCover, c.coverOk),
  (l10n.checkSpine, c.spineOk),
  (l10n.checkPages, c.pagesOk),
  (l10n.checkNoMold, c.noMold),
  (l10n.checkNotes, c.hasNotes),
];

/// Phiếu kiểm định (chỉ xem): tình trạng, checklist, báo cáo, ảnh kho, ước tính và giá đề xuất (SRS 6.2).
class InspectionView extends StatelessWidget {
  const InspectionView({super.key, required this.inspection});

  final Inspection inspection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final i = inspection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusPill(
              i.result == InspectionResult.pass
                  ? l10n.inspectionPass
                  : l10n.inspectionFail,
              tone: i.result == InspectionResult.pass
                  ? StatusTone.success
                  : StatusTone.danger,
            ),
            StatusPill(i.condition.label(l10n), tone: i.condition.tone),
            if (i.checklist.signature != SignatureStatus.none)
              StatusPill(
                i.checklist.signature == SignatureStatus.verified
                    ? l10n.signatureVerified
                    : l10n.signatureUnverified,
                tone: StatusTone.info,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (label, ok) in checklistItems(l10n, i.checklist))
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 18,
                    color: ok ? c.success : c.tertiaryText,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(label, style: context.textStyles.bodyMedium),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(i.conditionReport, style: context.textStyles.bodyLarge),
        if (i.staffImageUrls.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          PhotoStrip(urls: i.staffImageUrls, size: 84),
        ],
        if (i.estimateLow != null ||
            i.proposedStart != null ||
            i.proposedReserve != null)
          const Divider(height: AppSpacing.xl),
        if (i.estimateLow != null && i.estimateHigh != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.estimate,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: c.secondaryText,
                  ),
                ),
              ),
              Text(
                '${formatVnd(i.estimateLow!)} – ${formatVnd(i.estimateHigh!)}',
                style: context.textStyles.bodyMedium,
              ),
            ],
          ),
        if (i.proposedStart != null)
          MoneyLine(l10n.proposedStart, i.proposedStart!),
        if (i.proposedReserve != null)
          MoneyLine(l10n.proposedReserve, i.proposedReserve!, strong: true),
        if (i.counterReserve != null)
          MoneyLine(l10n.counterReserve, i.counterReserve!),
      ],
    );
  }
}
