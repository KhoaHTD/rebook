import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:book_marketplace/app/app.dart';

void main() {
  // URL web dạng /books/123 thay vì /#/books/123 (firebase.json đã rewrite về index.html).
  usePathUrlStrategy();
  runApp(const ProviderScope(child: BookMarketplaceApp()));
}
