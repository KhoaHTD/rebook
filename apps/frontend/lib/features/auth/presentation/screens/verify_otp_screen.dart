import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/auth/presentation/providers/auth_controller.dart';
import 'package:book_marketplace/features/auth/presentation/widgets/auth_layout.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';

/// Nhập mã OTP 6 số gửi qua email. Đúng mã → đăng nhập luôn, router tự chuyển trang.
class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  var _wait = 60;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _wait = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_wait <= 1) t.cancel();
      if (mounted) setState(() => _wait--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!AuthValidators.otp(_code.text)) return;
    await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(widget.email, _code.text);
  }

  Future<void> _resend() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resendOtp(widget.email);
    if (!mounted) return;
    if (ok) {
      showInfoSnack(context, context.l10n.otpSent);
      _startCooldown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);
    return AuthLayout(
      title: l10n.otpTitle,
      subtitle: l10n.otpSubtitle(widget.email),
      children: [
        TextField(
          controller: _code,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: context.textStyles.headlineMedium?.copyWith(
            letterSpacing: 12,
            fontFamily: AppFonts.sans,
          ),
          decoration: InputDecoration(labelText: l10n.otpCode, counterText: ''),
          onChanged: (v) {
            if (v.length == 6) _submit();
          },
        ),
        if (state.hasError) AuthError(errorMessage(context, state.error!)),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: state.isLoading ? null : _submit,
          child: Text(l10n.confirm),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _wait > 0 || state.isLoading ? null : _resend,
          child: Text(_wait > 0 ? l10n.otpResendIn(_wait) : l10n.otpResend),
        ),
      ],
    );
  }
}
