import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/auth/presentation/providers/login_controller.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';

/// Sau khi đăng nhập thành công, router tự chuyển hướng (xem `app_router.dart`).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(loginControllerProvider.notifier)
        .login(email: _email.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final login = ref.watch(loginControllerProvider);
    String? required(String? v) =>
        (v == null || v.isEmpty) ? l10n.fieldRequired : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 64,
                    color: context.colors.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _email,
                    decoration: InputDecoration(labelText: l10n.email),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: required,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _password,
                    decoration: InputDecoration(labelText: l10n.password),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    validator: required,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (login.hasError) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      errorMessage(context, login.error!),
                      style: TextStyle(color: context.colors.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: login.isLoading ? null : _submit,
                    child: login.isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.loginButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
