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

/// Đăng ký → gửi OTP email → màn nhập OTP (SRS 3 — chung).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .register(
          fullName: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
        );
    if (ok && mounted) {
      context.go(
        Uri(
          path: Routes.verifyOtp,
          queryParameters: {'email': _email.text.trim()},
        ).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);

    return AuthLayout(
      title: l10n.authRegisterTitle,
      subtitle: l10n.authRegisterSubtitle,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RuleField(
                controller: _name,
                rule: Rules.fullName,
                label: l10n.fullName,
              ),
              RuleField(
                controller: _email,
                rule: Rules.email,
                label: l10n.email,
              ),
              RuleField(
                controller: _phone,
                rule: Rules.phone,
                label: l10n.phone,
              ),
              RuleField(
                controller: _password,
                rule: Rules.password,
                label: l10n.password,
                obscure: true,
              ),
              RuleField(
                controller: _confirm,
                rule: Rules.confirmPassword,
                label: l10n.confirmPassword,
                obscure: true,
                validator: (v) =>
                    v == _password.text ? null : l10n.passwordMismatch,
                onSubmitted: (_) => _submit(),
                bottom: 0,
              ),
            ],
          ),
        ),
        if (state.hasError) AuthError(errorMessage(context, state.error!)),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: state.isLoading ? null : _submit,
          child: Text(l10n.register),
        ),
        const SizedBox(height: AppSpacing.md),
        AuthFooterLink(
          text: l10n.haveAccount,
          action: l10n.login,
          onTap: () => context.go(Routes.login),
        ),
      ],
    );
  }
}
