import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/features/account/presentation/providers/account_providers.dart';
import 'package:book_marketplace/shared/widgets/address_book_list.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/form_widgets.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Địa chỉ của tôi: danh sách (tên | số điện thoại, địa chỉ, nhãn Mặc định / Văn phòng), bấm một dòng để sửa,
/// nút "Thêm địa chỉ mới" ghim ở đáy.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(addressBookProvider);
    return AppPage(
      title: l10n.addresses,
      showBack: true,
      bottomBar: PinnedBar(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: OutlinedButton.icon(
              onPressed: () => context.push(Routes.addressNew),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addrAddNew),
            ),
          ),
        ),
      ),
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(addressBookProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.location_off_outlined,
                  title: l10n.noAddresses,
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: AddressBookList(
                    items: items,
                    onTap: (a) => context.push(Routes.addressEdit(a.id)),
                  ),
                ),
        ),
      ],
    );
  }
}
