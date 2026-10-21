import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/catalog/data/api_catalog_repository.dart';
import 'package:book_marketplace/features/catalog/data/fake_catalog_repository.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';

part 'catalog_repository_provider.g.dart';

/// Presentation chỉ import file này, không import trực tiếp Api/Fake repository.
@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(Ref ref) => Env.useMock
    ? FakeCatalogRepository()
    : ApiCatalogRepository(ref.watch(restClientProvider));
