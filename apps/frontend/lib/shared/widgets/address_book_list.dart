import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Danh sách địa chỉ kiểu sổ địa chỉ: tên | số điện thoại, địa chỉ, nhãn Mặc định / Văn phòng.
/// Sổ địa chỉ và màn xác nhận đặt hàng dùng chung để hai nơi luôn giống nhau.
class AddressBookList extends StatelessWidget {
  const AddressBookList({
    super.key,
    required this.items,
    required this.onTap,
    this.selectedId,
  });

  final List<Address> items;
  final ValueChanged<Address> onTap;

  /// Có giá trị khi đang chọn địa chỉ: dòng này có dấu tích thay cho mũi tên.
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final secondary = text.bodyMedium?.copyWith(color: c.secondaryText);
    return InfoPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, a) in items.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 16, color: c.separator),
            InkWell(
              onTap: () => onTap(a),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: a.receiver,
                              style: text.titleMedium,
                              children: [
                                TextSpan(
                                  text: '  |  ${a.phone}',
                                  style: secondary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(a.detail, style: secondary),
                          Text(
                            [
                              a.ward,
                              a.district,
                              a.province,
                            ].where((s) => s.isNotEmpty).join(', '),
                            style: secondary,
                          ),
                          if (a.isDefault || a.type == AddressType.office) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: AppSpacing.sm,
                              children: [
                                if (a.isDefault) PillBadge(l10n.defaultBadge),
                                if (a.type == AddressType.office)
                                  PillBadge(l10n.addrTypeOffice),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (selectedId == null)
                      Icon(Icons.chevron_right_rounded, color: c.tertiaryText)
                    else if (a.id == selectedId)
                      Icon(
                        Icons.check_circle_rounded,
                        color: context.colors.primary,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
