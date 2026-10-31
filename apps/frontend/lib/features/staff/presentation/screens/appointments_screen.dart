import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/shared/widgets/form_widgets.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/staff/presentation/providers/staff_providers.dart';
import 'package:book_marketplace/features/staff/presentation/widgets/consignment_row.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/photo_picker.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Nhận sách tại kho bằng mã lịch hẹn + danh sách lịch hẹn sắp tới (SRS 6.1).
class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(staffAppointmentsProvider);
    final upcoming = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.todayAppointments),
        const SizedBox(height: AppSpacing.md),
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(staffAppointmentsProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.event_available_rounded,
                  title: l10n.nothingToDo,
                )
              : Column(
                  children: [
                    for (final c in items)
                      ConsignmentRow(
                        consignment: c,
                        subtitle: [
                          c.appointmentCode ?? '',
                          if (c.appointmentAt != null)
                            formatShortDateTime(c.appointmentAt!),
                          c.sellerName,
                        ].join(' · '),
                      ),
                  ],
                ),
        ),
      ],
    );
    final wide = context.windowSize == WindowSize.expanded;
    return AppPage(
      title: l10n.navAppointments,
      showBack: false,
      onRefresh: () => ref.refresh(staffAppointmentsProvider.future),
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 400, child: _CheckInForm()),
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: upcoming),
            ],
          )
        else ...[
          const _CheckInForm(),
          const SizedBox(height: AppSpacing.xl),
          upcoming,
        ],
      ],
    );
  }
}

class _CheckInForm extends ConsumerStatefulWidget {
  const _CheckInForm();

  @override
  ConsumerState<_CheckInForm> createState() => _CheckInFormState();
}

class _CheckInFormState extends ConsumerState<_CheckInForm> {
  /// Mã kệ để trống được (nhập sau).
  static final _shelfRule = Rules.shelfCode.copyWith(optional: true);

  final _code = TextEditingController();
  final _shelf = TextEditingController();
  var _receipts = <String>[];
  var _formKey = UniqueKey();

  @override
  void dispose() {
    _code.dispose();
    _shelf.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final c = await ref
        .read(staffActionsProvider.notifier)
        .checkIn(
          Rules.appointmentCode.value(_code.text),
          receipts: _receipts,
          shelf: _shelf.text.trim().isEmpty
              ? null
              : Rules.shelfCode.value(_shelf.text),
        );
    if (!mounted) return;
    if (c == null) {
      showErrorSnack(context, ref.read(staffActionsProvider).error!);
      return;
    }
    showInfoSnack(context, context.l10n.checkedIn(c.warehouseCode ?? ''));
    _code.clear();
    _shelf.clear();
    setState(() {
      _receipts = [];
      _formKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = ref.watch(staffActionsProvider).isLoading;
    return InfoPanel(
      key: _formKey,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.checkIn, style: context.textStyles.titleLarge),
          Text(l10n.checkInHint, style: context.textStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          RuleField(
            controller: _code,
            rule: Rules.appointmentCode,
            label: l10n.appointmentCode,
            onChanged: (_) => setState(() {}),
          ),
          RuleField(
            controller: _shelf,
            rule: _shelfRule,
            label: l10n.shelfCode,
            onChanged: (_) => setState(() {}),
          ),
          Text(l10n.receiptPhotos, style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          PhotoPickerField(
            folder: 'receipts',
            max: 4,
            onChanged: (urls) => _receipts = urls,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed:
                busy ||
                    !Rules.appointmentCode.isValid(_code.text) ||
                    !_shelfRule.isValid(_shelf.text)
                ? null
                : _submit,
            child: Text(l10n.checkIn),
          ),
        ],
      ),
    );
  }
}
