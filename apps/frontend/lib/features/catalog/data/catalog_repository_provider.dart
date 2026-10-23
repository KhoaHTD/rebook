import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/catalog/data/api_catalog_repository.dart';
import 'package:book_marketplace/features/catalog/data/fake_catalog_repository.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

part 'catalog_repository_provider.g.dart';

@riverpod
CatalogRepository catalogRepository(Ref ref) => Env.useMock
    ? FakeCatalogRepository(ref.watch(fakeStoreProvider))
    : ApiCatalogRepository(ref.watch(restClientProvider));
