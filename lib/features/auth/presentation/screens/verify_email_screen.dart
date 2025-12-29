/// Project Neo - Email Verification Screen
///
/// High-Tech Minimalista OTP verification screen.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../../core/theme/neo_widgets.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  Timer? _resendTimer;
  int _resendCountdown = 0;
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }
  
  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }
  
  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }
  
  String get _otpCode => _controllers.map((c) => c.text).join();
  
  void _handleVerify() {
    if (_otpCode.length == 6) {
      ref.read(authProvider.notifier).verifyEmailOtp(_otpCode);
    }
  }
  
  void _handleResend() {
    if (_resendCountdown == 0) {
      ref.read(authProvider.notifier).resendVerificationEmail();
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código reenviado'),
          backgroundColor: NeoColors.success,
        ),
      );
    }
  }
  
  void _onCodeChanged(int index, String value) {
    // Handle paste - if pasted more than 1 char, distribute across fields
    if (value.length > 1) {
      final chars = value.split('');
      for (var i = 0; i < chars.length && (index + i) < 6; i++) {
        _controllers[index + i].text = chars[i];
      }
      final nextIndex = (index + chars.length).clamp(0, 5);
      _focusNodes[nextIndex].requestFocus();
      setState(() {});
    } 
    // Handle single char - move to next field
    else if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto-verify when complete
    if (_otpCode.length == 6) {
      FocusScope.of(context).unfocus();
      _handleVerify();
    }
    setState(() {}); // Update UI to show typed characters
  }
  
  void _onKeyPressed(int index, RawKeyEvent event) {
    // Handle backspace - move to previous field if current is empty
    if (event is RawKeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty && 
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: NeoColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
      
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });
    
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NeoSpacing.lg),
          child: Column(
            children: [
              // Back button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: NeoColors.card,
                        borderRadius: BorderRadius.circular(NeoSpacing.smallRadius),
                        border: Border.all(
                          color: NeoColors.border,
                          width: NeoSpacing.borderWidth,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: NeoColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              
              const Spacer(),
              
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: NeoColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: NeoColors.border,
                    width: NeoSpacing.borderWidth,
                  ),
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ).animate().fadeIn(duration: 500.ms).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
              ),
              
              const SizedBox(height: NeoSpacing.lg),
              
              Text('Verifica tu correo', style: NeoTextStyles.displaySmall)
                  .animate().fadeIn(duration: 500.ms, delay: 100.ms),
              
              const SizedBox(height: NeoSpacing.sm),
              
              Text(
                'Ingresa el código de 6 dígitos\nenviado a ${authState.pendingEmail ?? "tu correo"}',
                style: NeoTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
              
              const SizedBox(height: NeoSpacing.xxl),
              
              // OTP Input
              _buildOtpInput(authState)
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms),
              
              const SizedBox(height: NeoSpacing.xl),
              
              // Verify button
              NeoButton(
                text: 'Verificar',
                onPressed: authState.isLoading || _otpCode.length < 6
                    ? null
                    : _handleVerify,
                isLoading: authState.isLoading,
                width: double.infinity,
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
              
              const SizedBox(height: NeoSpacing.md),
              
              // Resend button
              TextButton(
                onPressed: _resendCountdown == 0 ? _handleResend : null,
                child: Text(
                  _resendCountdown > 0
                      ? 'Reenviar en ${_resendCountdown}s'
                      : 'Reenviar código',
                  style: NeoTextStyles.labelLarge.copyWith(
                    color: _resendCountdown > 0
                        ? NeoColors.textTertiary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
              
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOtpInput(AuthState authState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 38,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) => _onKeyPressed(index, event),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: null, // Allow paste
              enabled: !authState.isLoading,
              style: NeoTextStyles.headlineMedium.copyWith(
                color: NeoColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: NeoColors.inputFill,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NeoSpacing.inputRadius),
                  borderSide: BorderSide(
                    color: _controllers[index].text.isNotEmpty
                        ? Theme.of(context).colorScheme.primary
                        : NeoColors.border,
                    width: NeoSpacing.borderWidth,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NeoSpacing.inputRadius),
                  borderSide: BorderSide(
                    color: _controllers[index].text.isNotEmpty
                        ? Theme.of(context).colorScheme.primary
                        : NeoColors.border,
                    width: NeoSpacing.borderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NeoSpacing.inputRadius),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => _onCodeChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}

