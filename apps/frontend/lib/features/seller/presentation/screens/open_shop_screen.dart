import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/shared/widgets/form_widgets.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/seller/presentation/providers/seller_providers.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Mở shop: tên, địa chỉ lấy hàng, tài khoản nhận tiền (SRS 2). Đã có shop → sửa thông tin.
class OpenShopScreen extends ConsumerWidget {
  const OpenShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(myShopProvider);
    final l10n = context.l10n;
    final editing = shop.value != null;
    return AppPage(
      title: editing ? l10n.editShop : l10n.openShopTitle,
      subtitle: editing ? null : l10n.openShopSubtitle,
      showBack: true,
      children: [
        AsyncValueView(
          value: shop,
          onRetry: () => ref.invalidate(myShopProvider),
          data: (s) => Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _ShopForm(initial: s),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopForm extends ConsumerStatefulWidget {
  const _ShopForm({this.initial});

  final Shop? initial;

  @override
  ConsumerState<_ShopForm> createState() => _ShopFormState();
}

class _ShopFormState extends ConsumerState<_ShopForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _desc = TextEditingController(text: widget.initial?.description);
  late final _pickup = TextEditingController(
    text: widget.initial?.pickupAddress,
  );
  final _bank = TextEditingController();
  final _account = TextEditingController();
  final _holder = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _desc, _pickup, _bank, _account, _holder]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final draft = ShopDraft(
      name: Rules.shopName.value(_name.text),
      description: Rules.description.value(_desc.text).isEmpty
          ? null
          : Rules.description.value(_desc.text),
      pickupAddress: Rules.pickupAddress.value(_pickup.text),
      bankName: Rules.bankName.value(_bank.text),
      bankAccount: Rules.bankNumber.value(_account.text),
      bankHolder: Rules.bankHolder.value(_holder.text),
    );
    final actions = ref.read(sellerActionsProvider.notifier);
    final shop = widget.initial == null
        ? await actions.openShop(draft)
        : await actions.updateShop(draft);
    if (!mounted) return;
    if (shop == null) {
      showErrorSnack(context, ref.read(sellerActionsProvider).error!);
      return;
    }
    if (widget.initial == null) {
      showInfoSnack(context, context.l10n.shopOpened);
      context.go(Routes.newListing);
    } else {
      showInfoSnack(context, context.l10n.saved);
      context.go(Routes.seller);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = ref.watch(sellerActionsProvider).isLoading;
    // Sửa shop không bắt buộc nhập lại tài khoản ngân hàng.
    final editing = widget.initial != null;
    InputRule bank(InputRule r) => r.copyWith(optional: editing);

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RuleField(
            controller: _name,
            rule: Rules.shopName,
            label: l10n.shopName,
          ),
          RuleField(
            controller: _desc,
            rule: Rules.description,
            label: l10n.shopDescription,
            minLines: 2,
            maxLines: 4,
          ),
          RuleField(
            controller: _pickup,
            rule: Rules.pickupAddress,
            label: l10n.pickupAddress,
          ),
          Text(l10n.payoutInfo, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          RuleField(
            controller: _bank,
            rule: bank(Rules.bankName),
            label: l10n.bankName,
          ),
          RuleField(
            controller: _account,
            rule: bank(Rules.bankNumber),
            label: l10n.bankAccount,
          ),
          RuleField(
            controller: _holder,
            rule: bank(Rules.bankHolder),
            label: l10n.bankHolder,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: busy ? null : _submit,
              child: Text(
                widget.initial == null ? l10n.openShopButton : l10n.save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
