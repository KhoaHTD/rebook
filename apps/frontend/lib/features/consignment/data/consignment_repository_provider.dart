import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/consignment/data/api_consignment_repository.dart';
import 'package:book_marketplace/features/consignment/data/fake_consignment_repository.dart';
import 'package:book_marketplace/features/consignment/domain/consignment_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

part 'consignment_repository_provider.g.dart';

@riverpod
ConsignmentRepository consignmentRepository(Ref ref) => Env.useMock
    ? FakeConsignmentRepository(ref.watch(fakeStoreProvider))
    : ApiConsignmentRepository(ref.watch(restClientProvider));
