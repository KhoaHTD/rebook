import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/clock.dart';
import 'package:book_marketplace/core/utils/formatters.dart';

class CountdownText extends ConsumerWidget {
  const CountdownText({super.key, required this.endsAt, this.style});

  final DateTime endsAt;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final remaining = endsAt.difference(now);
    final ended = remaining <= Duration.zero;

    return Text(
      ended
          ? context.l10n.auctionEnded
          : context.l10n.auctionEndsIn(formatCountdown(remaining)),
      style: (style ?? context.textStyles.labelLarge)?.copyWith(
        color: ended ? context.colors.outline : context.appColors.auctionLive,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
