/// Project Neo - Register Screen
///
/// High-Tech Minimalista registration screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../../core/theme/neo_widgets.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes aceptar los términos'),
            backgroundColor: NeoColors.warning,
          ),
        );
        return;
      }
      
      ref.read(authProvider.notifier).signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _usernameController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: NeoColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
      
      if (next.status == AuthStatus.needsVerification) {
        context.go('/verify-email');
      }
    });
    
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: NeoSpacing.md),
                
                // Back button
                _buildTopBar()
                    .animate()
                    .fadeIn(duration: 400.ms),
                    
                const SizedBox(height: NeoSpacing.xl),
                
                // Header
                _buildHeader()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.1, end: 0),
                    
                const SizedBox(height: NeoSpacing.lg),
                
                // Form card
                _buildFormCard(authState)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 150.ms),
                    
                const SizedBox(height: NeoSpacing.md),
                
                // Terms checkbox
                _buildTermsRow()
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 250.ms),
                    
                const SizedBox(height: NeoSpacing.lg),
                
                // Register button
                NeoButton(
                  text: 'Crear Cuenta',
                  onPressed: authState.isLoading ? null : _handleRegister,
                  isLoading: authState.isLoading,
                  width: double.infinity,
                ).animate()
                    .fadeIn(duration: 500.ms, delay: 350.ms),
                    
                const SizedBox(height: NeoSpacing.lg),
                
                // Login link
                _buildLoginLink()
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 450.ms),
                    
                const SizedBox(height: NeoSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopBar() {
    return Row(
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
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: NeoColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: NeoColors.border,
              width: NeoSpacing.borderWidth,
            ),
          ),
          child: Icon(
            Icons.person_add_alt_1_rounded,
            size: 28,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: NeoSpacing.md),
        Text('Únete a Neo', style: NeoTextStyles.displaySmall),
        const SizedBox(height: NeoSpacing.xs),
        Text(
          'Crea tu cuenta',
          style: NeoTextStyles.bodyMedium,
        ),
      ],
    );
  }
  
  Widget _buildFormCard(AuthState authState) {
    return NeoCard(
      padding: const EdgeInsets.all(NeoSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            NeoTextField(
              label: 'Nombre de usuario',
              hint: 'tu_nombre',
              controller: _usernameController,
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: NeoColors.textTertiary,
                size: 20,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                if (value.length < 3) return 'Mínimo 3 caracteres';
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                  return 'Solo letras, números y _';
                }
                return null;
              },
            ),
            
            const SizedBox(height: NeoSpacing.md),
            
            NeoTextField(
              label: 'Correo electrónico',
              hint: 'tu@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(
                Icons.mail_outline_rounded,
                color: NeoColors.textTertiary,
                size: 20,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Correo inválido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: NeoSpacing.md),
            
            NeoTextField(
              label: 'Contraseña',
              hint: '••••••••',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: NeoColors.textTertiary,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: NeoColors.textTertiary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                if (value.length < 8) return 'Mínimo 8 caracteres';
                return null;
              },
            ),
            
            const SizedBox(height: NeoSpacing.md),
            
            NeoTextField(
              label: 'Confirmar contraseña',
              hint: '••••••••',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: NeoColors.textTertiary,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: NeoColors.textTertiary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'No coinciden';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _acceptedTerms 
                  ? Theme.of(context).colorScheme.primary 
                  : NeoColors.inputFill,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _acceptedTerms 
                    ? Theme.of(context).colorScheme.primary 
                    : NeoColors.border,
                width: 1,
              ),
            ),
            child: _acceptedTerms
                ? const Icon(Icons.check, size: 14, color: NeoColors.textPrimary)
                : null,
          ),
          const SizedBox(width: NeoSpacing.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: NeoTextStyles.bodySmall,
                children: [
                  const TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'Términos',
                    style: NeoTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const TextSpan(text: ' y '),
                  TextSpan(
                    text: 'Política de Privacidad',
                    style: NeoTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿Ya tienes cuenta? ', style: NeoTextStyles.bodyMedium),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text(
            'Inicia Sesión',
            style: NeoTextStyles.labelLarge.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
