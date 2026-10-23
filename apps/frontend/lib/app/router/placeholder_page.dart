import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Trang tạm cho màn hình chưa làm xong (giai đoạn triển khai) và trang 404.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    this.notFound = false,
  });

  final String title;
  final bool notFound;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: title,
      children: [
        EmptyState(
          icon: notFound
              ? Icons.explore_off_outlined
              : Icons.construction_rounded,
          title: notFound ? context.l10n.notFound : context.l10n.comingSoon,
        ),
      ],
    );
  }
}
