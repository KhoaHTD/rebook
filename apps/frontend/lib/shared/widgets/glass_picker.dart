import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/glass_menu.dart';

/// Popup chọn ngày + giờ bằng bánh xe cuộn, kính bo góc, gọn (rộng tối đa 340).
/// Thay cho `showDatePicker` + `showTimePicker` của Material: hai hộp đó nền trong suốt trong theme kính
/// và quá to trên điện thoại. Trả về `null` khi bấm Hủy / ra ngoài.
Future<DateTime?> showGlassDateTimePicker(
  BuildContext context, {
  required DateTime initial,
  required DateTime min,
  required DateTime max,
  String? title,
}) {
  return showGeneralDialog<DateTime>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: CoverPalette.scrim,
    transitionDuration: AppDurations.normal,
    pageBuilder: (context, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: _PickerCard(
            initial: initial,
            min: min,
            max: max,
            title: title,
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _PickerCard extends StatefulWidget {
  const _PickerCard({
    required this.initial,
    required this.min,
    required this.max,
    this.title,
  });

  final DateTime initial;
  final DateTime min;
  final DateTime max;
  final String? title;

  @override
  State<_PickerCard> createState() => _PickerCardState();
}

class _PickerCardState extends State<_PickerCard> {
  late DateTime _value = _clamp(widget.initial);

  DateTime _clamp(DateTime d) => d.isBefore(widget.min)
      ? widget.min
      : (d.isAfter(widget.max) ? widget.max : d);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ink = context.colors.onSurface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      type: MaterialType.transparency,
      child: GlassSurface(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md + 2,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    widget.title!,
                    textAlign: TextAlign.center,
                    style: context.textStyles.titleMedium,
                  ),
                ),
              SizedBox(
                height: 188,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: dark ? Brightness.dark : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 19,
                        color: ink,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    use24hFormat: true,
                    initialDateTime: _value,
                    minimumDate: widget.min,
                    maximumDate: widget.max,
                    onDateTimeChanged: (d) => _value = d,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pop(_value),
                      child: Text(l10n.confirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
