import 'package:flutter/widgets.dart';

import 'package:book_marketplace/app/l10n/generated/app_localizations.dart';

export 'package:book_marketplace/app/l10n/generated/app_localizations.dart';

extension L10nX on BuildContext {
  /// Mọi chuỗi hiển thị cho người dùng đi qua đây: `context.l10n.buyNow`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
