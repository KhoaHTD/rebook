import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/home/data/api_home_repository.dart';
import 'package:book_marketplace/features/home/data/fake_home_repository.dart';
import 'package:book_marketplace/features/home/domain/home_repository.dart';

part 'home_repository_provider.g.dart';

/// Presentation chỉ import file này, không import trực tiếp Api/Fake repository.
@Riverpod(keepAlive: true)
HomeRepository homeRepository(Ref ref) => Env.useMock
    ? FakeHomeRepository()
    : ApiHomeRepository(ref.watch(restClientProvider));
