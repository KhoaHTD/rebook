import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Một dòng ký gửi trong các danh sách của nhân viên: poster nhỏ, tên, người gửi, trạng thái, giá mong muốn.
class ConsignmentRow extends StatelessWidget {
  const ConsignmentRow({
    super.key,
    required this.consignment,
    this.trailing = const [],
    this.onTap,
    this.subtitle,
  });

  final Consignment consignment;
  final List<Widget> trailing;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = consignment;
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.sidebar,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        child: InkWell(
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadius.card,
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: LayoutBuilder(
              builder: (context, box) {
                // Hẹp (điện thoại): nút xuống hàng riêng, không bóp chữ của sách.
                final stacked = box.maxWidth < 480 && trailing.isNotEmpty;
                final info = Row(
                  children: [
                    BookPoster(
                      title: c.book.title,
                      author: '',
                      coverUrl: c.book.coverUrl,
                      seed: c.book.id,
                      width: 48,
                      shadow: false,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.titleSmall,
                          ),
                          Text(
                            subtitle ??
                                '${c.sellerName} · ${formatShortDateTime(c.createdAt)}',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: colors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              StatusPill(
                                c.status.label(l10n),
                                tone: c.status.tone,
                              ),
                              PriceText(
                                c.expectedPrice,
                                style: context.textStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!stacked)
                      for (final t in trailing) ...[
                        const SizedBox(width: AppSpacing.sm),
                        t,
                      ],
                  ],
                );
                if (!stacked) return info;
                return Column(
                  children: [
                    info,
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (var i = 0; i < trailing.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          Expanded(child: trailing[i]),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
