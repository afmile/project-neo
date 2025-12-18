/// Project Neo - High-Tech Minimalista Widgets
///
/// Solid, clean widgets without glassmorphism.
/// Designed for OLED displays with sharp, minimal aesthetics.
library;

import 'package:flutter/material.dart';
import 'neo_theme.dart';

/// A solid card widget for Bento Grid layouts
class NeoCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  
  const NeoCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(NeoSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? NeoColors.card,
        borderRadius: BorderRadius.circular(NeoSpacing.cardRadius),
        border: Border.all(
          color: borderColor ?? NeoColors.border,
          width: NeoSpacing.borderWidth,
        ),
      ),
      child: child,
    );
    
    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    
    return content;
  }
}

/// Primary action button with accent color
class NeoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final Color? color;
  
  const NeoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? Theme.of(context).colorScheme.primary;
    
    if (isOutlined) {
      return SizedBox(
        width: width,
        height: 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: NeoColors.border,
              width: NeoSpacing.borderWidth,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _buildContent(accentColor),
        ),
      );
    }
    
    return SizedBox(
      width: width,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: NeoColors.textPrimary,
                ),
              )
            : _buildContent(NeoColors.textPrimary),
      ),
    );
  }
  
  Widget _buildContent(Color textColor) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: NeoSpacing.sm),
          Text(text, style: NeoTextStyles.button.copyWith(color: textColor)),
        ],
      );
    }
    return Text(text, style: NeoTextStyles.button.copyWith(color: textColor));
  }
}

/// Social login button (Google, Apple)
class SocialLoginButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? iconWidget;
  final Color? backgroundColor;
  final Color? textColor;
  
  const SocialLoginButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.iconWidget,
    this.backgroundColor,
    this.textColor,
  });
  
  /// Google sign in button
  factory SocialLoginButton.google({
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SocialLoginButton(
      text: 'Continuar con Google',
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: NeoColors.card,
      textColor: NeoColors.textPrimary,
      iconWidget: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            'G',
            style: NeoTextStyles.labelLarge.copyWith(
              color: const Color(0xFF4285F4),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Apple sign in button
  factory SocialLoginButton.apple({
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SocialLoginButton(
      text: 'Continuar con Apple',
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: NeoColors.card,
      textColor: NeoColors.textPrimary,
      iconWidget: const Icon(Icons.apple, size: 22, color: NeoColors.textPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? NeoColors.card,
          foregroundColor: textColor ?? NeoColors.textPrimary,
          side: const BorderSide(
            color: NeoColors.border,
            width: NeoSpacing.borderWidth,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor ?? NeoColors.textPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (iconWidget != null) ...[
                    iconWidget!,
                    const SizedBox(width: NeoSpacing.md),
                  ],
                  Text(
                    text,
                    style: NeoTextStyles.button.copyWith(
                      color: textColor ?? NeoColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Text field with minimal styling
class NeoTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;
  final FocusNode? focusNode;
  
  const NeoTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: NeoTextStyles.labelMedium,
        ),
        const SizedBox(height: NeoSpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          maxLines: maxLines,
          focusNode: focusNode,
          style: NeoTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// Divider with "OR" text
class NeoOrDivider extends StatelessWidget {
  final String text;
  
  const NeoOrDivider({
    super.key,
    this.text = 'O',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: NeoColors.border,
            thickness: NeoSpacing.borderWidth,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
          child: Text(
            text,
            style: NeoTextStyles.labelMedium,
          ),
        ),
        const Expanded(
          child: Divider(
            color: NeoColors.border,
            thickness: NeoSpacing.borderWidth,
          ),
        ),
      ],
    );
  }
}

/// Bento Grid cell with icon and title
class BentoCell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? accentColor;
  final int flex;
  
  const BentoCell({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.accentColor,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Theme.of(context).colorScheme.primary;
    
    return NeoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const Spacer(),
          Text(title, style: NeoTextStyles.headlineSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: NeoTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}
