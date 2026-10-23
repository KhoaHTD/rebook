import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:book_marketplace/app/app.dart';

/// Web quản trị (Staff / Admin):
/// `flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env/dev.json`
void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: AdminApp()));
}
