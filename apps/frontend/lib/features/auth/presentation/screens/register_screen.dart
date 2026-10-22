import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
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
    InputDecoration d(String label) => InputDecoration(labelText: label);
    const gap = SizedBox(height: AppSpacing.md);

    return AuthLayout(
      title: l10n.authRegisterTitle,
      subtitle: l10n.authRegisterSubtitle,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: d(l10n.fullName),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
              ),
              gap,
              TextFormField(
                controller: _email,
                decoration: d(l10n.email),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    AuthValidators.email(v ?? '') ? null : l10n.emailInvalid,
              ),
              gap,
              TextFormField(
                controller: _phone,
                decoration: d(l10n.phone),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    AuthValidators.phone(v ?? '') ? null : l10n.phoneInvalid,
              ),
              gap,
              TextFormField(
                controller: _password,
                decoration: d(l10n.password),
                obscureText: true,
                validator: (v) => AuthValidators.password(v ?? '')
                    ? null
                    : l10n.passwordTooShort,
              ),
              gap,
              TextFormField(
                controller: _confirm,
                decoration: d(l10n.confirmPassword),
                obscureText: true,
                validator: (v) =>
                    v == _password.text ? null : l10n.passwordMismatch,
                onFieldSubmitted: (_) => _submit(),
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
