import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/error/app_exception.dart';

/// Đổi lỗi bất kỳ thành câu thông báo đã dịch.
String errorMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  return switch (AppException.from(error)) {
    NetworkException() => l10n.errorNetwork,
    UnauthorizedException() => l10n.errorUnauthorized,
    ForbiddenException(:final message) => message ?? l10n.errorForbidden,
    // 4xx: backend đã viết sẵn thông báo cho người dùng (vd "Chỉ còn 1 cuốn").
    final ServerException e when e.isClientError && e.message != null =>
      e.message!,
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.colors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              errorMessage(context, error),
              textAlign: TextAlign.center,
              style: context.textStyles.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
