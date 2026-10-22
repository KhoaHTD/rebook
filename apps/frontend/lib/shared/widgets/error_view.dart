import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/core/error/app_exception.dart';

/// Đổi lỗi bất kỳ thành câu thông báo đã dịch.
String errorMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  final e = AppException.from(error);
  if (e is ServerException && e.code != null) {
    final byCode = switch (e.code) {
      ErrorCodes.priceChanged => l10n.errPriceChanged,
      ErrorCodes.bidTooLow => l10n.errBidTooLow,
      ErrorCodes.alreadyLeading => l10n.errAlreadyLeading,
      ErrorCodes.limitExceeded => l10n.errLimitExceeded,
      ErrorCodes.notRegistered => l10n.errNotRegistered,
      ErrorCodes.lotClosed => l10n.errLotClosed,
      ErrorCodes.registrationClosed => l10n.errRegistrationClosed,
      ErrorCodes.auctionBanned => l10n.errAuctionBanned,
      ErrorCodes.outOfStock => l10n.errOutOfStock,
      ErrorCodes.ownListing => l10n.errOwnListing,
      ErrorCodes.insufficientBalance => l10n.errInsufficientBalance,
      ErrorCodes.invalidTransition => l10n.errInvalidTransition,
      ErrorCodes.invalidCredentials => l10n.errInvalidCredentials,
      ErrorCodes.invalidOtp => l10n.errInvalidOtp,
      ErrorCodes.emailTaken => l10n.errEmailTaken,
      ErrorCodes.notFound => l10n.errNotFound,
      _ => null,
    };
    if (byCode != null) return byCode;
  }
  return switch (e) {
    NetworkException() => l10n.errorNetwork,
    UnauthorizedException() => l10n.errorUnauthorized,
    ServerException(statusCode: 409) => l10n.errorConflict,
    ServerException() => l10n.errorServer,
    UnknownException() => l10n.errorUnknown,
  };
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage(context, error), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Hiện lỗi dạng snackbar (sau một hành động thất bại).
void showErrorSnack(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(errorMessage(context, error))));
}

/// Hiện thông báo ngắn (sau một hành động thành công).
void showInfoSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
