import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/admin/data/api_admin_repository.dart';
import 'package:book_marketplace/features/admin/data/fake_admin_repository.dart';
import 'package:book_marketplace/features/admin/domain/admin_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

part 'admin_repository_provider.g.dart';

@riverpod
AdminRepository adminRepository(Ref ref) => Env.useMock
    ? FakeAdminRepository(ref.watch(fakeStoreProvider))
    : ApiAdminRepository(ref.watch(restClientProvider));
