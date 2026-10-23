import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/auth/presentation/providers/auth_controller.dart';
import 'package:book_marketplace/features/auth/presentation/widgets/auth_layout.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';

/// Quên mật khẩu: bước 1 nhập email → nhận mã; bước 2 nhập mã + mật khẩu mới.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  var _codeSent = false;

  @override
  void dispose() {
    for (final c in [_email, _code, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = ref.read(authControllerProvider.notifier);
    if (!_codeSent) {
      if (await auth.forgotPassword(_email.text) && mounted) {
        setState(() => _codeSent = true);
      }
      return;
    }
    final ok = await auth.resetPassword(
      _email.text.trim(),
      _code.text,
      _password.text,
    );
    if (ok && mounted) {
      showInfoSnack(context, context.l10n.resetDone);
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);
    return AuthLayout(
      title: l10n.forgotTitle,
      subtitle: _codeSent
          ? l10n.otpSubtitle(_email.text.trim())
          : l10n.forgotSubtitle,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                enabled: !_codeSent,
                decoration: InputDecoration(labelText: l10n.email),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    AuthValidators.email(v ?? '') ? null : l10n.emailInvalid,
              ),
              if (_codeSent) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _code,
                  decoration: InputDecoration(labelText: l10n.otpCode),
                  keyboardType: TextInputType.number,
                  validator: (v) => AuthValidators.otp(v ?? '')
                      ? null
                      : l10n.otpInvalidLength,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(labelText: l10n.newPassword),
                  obscureText: true,
                  validator: (v) => AuthValidators.password(v ?? '')
                      ? null
                      : l10n.passwordTooShort,
                ),
              ],
            ],
          ),
        ),
        if (state.hasError) AuthError(errorMessage(context, state.error!)),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: state.isLoading ? null : _submit,
          child: Text(_codeSent ? l10n.save : l10n.sendCode),
        ),
      ],
    );
  }
}
