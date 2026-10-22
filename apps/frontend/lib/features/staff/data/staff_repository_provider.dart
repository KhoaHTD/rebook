import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/staff/data/api_staff_repository.dart';
import 'package:book_marketplace/features/staff/data/fake_staff_repository.dart';
import 'package:book_marketplace/features/staff/domain/staff_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

part 'staff_repository_provider.g.dart';

@riverpod
StaffRepository staffRepository(Ref ref) => Env.useMock
    ? FakeStaffRepository(ref.watch(fakeStoreProvider))
    : ApiStaffRepository(ref.watch(restClientProvider));
