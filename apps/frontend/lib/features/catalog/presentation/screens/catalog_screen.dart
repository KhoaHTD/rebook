import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/book_card.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(bookListProvider);
    final columns = switch (context.windowSize) {
      WindowSize.compact => 2,
      WindowSize.medium => 3,
      WindowSize.expanded => 5,
    };

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appTitle)),
      body: MaxWidthBox(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SearchBar(
                hintText: context.l10n.searchBooksHint,
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onSubmitted: ref.read(bookSearchQueryProvider.notifier).set,
              ),
            ),
            Expanded(
              child: AsyncValueView(
                value: books,
                onRetry: () => ref.invalidate(bookListProvider),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(child: Text(context.l10n.emptyBooks));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.52,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) => BookCard(
                      book: items[i],
                      onTap: () => context.go(Routes.bookDetail(items[i].id)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
