import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/shared/widgets/form_widgets.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';
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
              RuleField(
                controller: _email,
                enabled: !_codeSent,
                rule: Rules.email,
                label: l10n.email,
                bottom: _codeSent ? AppSpacing.lg : 0,
              ),
              if (_codeSent) ...[
                RuleField(
                  controller: _code,
                  rule: Rules.otp,
                  label: l10n.otpCode,
                ),
                RuleField(
                  controller: _password,
                  rule: Rules.password,
                  label: l10n.newPassword,
                  obscure: true,
                  bottom: 0,
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
