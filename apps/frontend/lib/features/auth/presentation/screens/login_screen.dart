import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/auth/presentation/providers/auth_controller.dart';
import 'package:book_marketplace/features/auth/presentation/widgets/auth_layout.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';

/// Đăng nhập. Dùng cho cả web quản trị ([allowSignUp] = false).
/// Thành công → router tự chuyển hướng (về `?from=` hoặc trang chủ).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.allowSignUp = true, this.denied = false});

  final bool allowSignUp;

  /// Tài khoản USER vừa bị đẩy ra khỏi web quản trị.
  final bool denied;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);
    return AuthLayout(
      title: widget.allowSignUp ? l10n.authWelcomeBack : l10n.adminAppTitle,
      subtitle: widget.allowSignUp ? l10n.authLoginSubtitle : null,
      showBack: widget.allowSignUp,
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  decoration: InputDecoration(labelText: l10n.email),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) =>
                      AuthValidators.email(v ?? '') ? null : l10n.emailInvalid,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(labelText: l10n.password),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) => AuthValidators.password(v ?? '')
                      ? null
                      : l10n.passwordTooShort,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        if (widget.allowSignUp)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(Routes.forgotPassword),
              child: Text(l10n.forgotPassword),
            ),
          ),
        if (widget.denied) AuthError(l10n.staffOnly),
        if (state.hasError) AuthError(errorMessage(context, state.error!)),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: state.isLoading ? null : _submit,
          child: state.isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.login),
        ),
        if (widget.allowSignUp) ...[
          const SizedBox(height: AppSpacing.md),
          AuthFooterLink(
            text: l10n.noAccount,
            action: l10n.register,
            onTap: () => context.push(Routes.register),
          ),
        ],
      ],
    );
  }
}
