/// Project Neo - Login Screen
///
/// High-Tech Minimalista styled login screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../../core/theme/neo_widgets.dart';
import '../../../../core/config/env_config.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _handleEmailLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }
  
  void _handleGoogleLogin() {
    ref.read(authProvider.notifier).signInWithGoogle();
  }
  
  void _handleAppleLogin() {
    ref.read(authProvider.notifier).signInWithApple();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    
    // Listen for errors and navigation
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
      
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
      
      if (next.status == AuthStatus.needsVerification) {
        context.push('/verify-email');
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
                SizedBox(height: size.height * 0.08),
                
                // Logo and title
                _buildHeader()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.1, end: 0),
                    
                SizedBox(height: size.height * 0.05),
                
                // Bento Grid style form
                _buildLoginCard(authState)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 150.ms)
                    .slideY(begin: 0.05, end: 0),
                    
                const SizedBox(height: NeoSpacing.lg),
                
                // Social login section (only if OAuth enabled)
                if (EnvConfig.enableOAuth)
                  _buildSocialSection(authState)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms),
                      
                const SizedBox(height: NeoSpacing.xl),
                
                // Register link
                _buildRegisterLink()
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
  
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: NeoColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: NeoColors.border,
              width: NeoSpacing.borderWidth,
            ),
          ),
          child: Icon(
            Icons.hub_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: NeoSpacing.lg),
        
        // Title
        Text(
          'PROJECT NEO',
          style: NeoTextStyles.displaySmall.copyWith(
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        
        // Subtitle
        Text(
          'Bienvenido de vuelta',
          style: NeoTextStyles.bodyMedium,
        ),
      ],
    );
  }
  
  Widget _buildLoginCard(AuthState authState) {
    return NeoCard(
      padding: const EdgeInsets.all(NeoSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
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
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu correo';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Correo inválido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: NeoSpacing.md),
            
            // Password field
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
                  _obscurePassword 
                      ? Icons.visibility_off_outlined 
                      : Icons.visibility_outlined,
                  color: NeoColors.textTertiary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu contraseña';
                }
                if (value.length < 6) {
                  return 'Mínimo 6 caracteres';
                }
                return null;
              },
            ),
            
            const SizedBox(height: NeoSpacing.sm),
            
            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: NeoTextStyles.labelMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: NeoSpacing.lg),
            
            // Login button
            NeoButton(
              text: 'Iniciar Sesión',
              onPressed: authState.isLoading ? null : _handleEmailLogin,
              isLoading: authState.isLoading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSocialSection(AuthState authState) {
    return Column(
      children: [
        const NeoOrDivider(text: 'o continúa con'),
        
        const SizedBox(height: NeoSpacing.lg),
        
        // Google button
        SocialLoginButton.google(
          onPressed: authState.isLoading ? null : _handleGoogleLogin,
          isLoading: authState.isLoading,
        ),
        
        const SizedBox(height: NeoSpacing.md),
        
        // Apple button
        SocialLoginButton.apple(
          onPressed: authState.isLoading ? null : _handleAppleLogin,
          isLoading: authState.isLoading,
        ),
      ],
    );
  }
  
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta? ',
          style: NeoTextStyles.bodyMedium,
        ),
        GestureDetector(
          onTap: () => context.push('/register'),
          child: Text(
            'Regístrate',
            style: NeoTextStyles.labelLarge.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
