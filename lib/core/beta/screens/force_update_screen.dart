/// Project Neo - Force Update Screen
///
/// Shown when the app version is below minimum required.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/env_config.dart';
import '../../theme/neo_theme.dart';
import '../version_check_provider.dart';

class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});
  
  // TODO: Replace with actual store URLs
  static const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.projectneo.project_neo';
  static const _appStoreUrl = 'https://apps.apple.com/app/neo/id000000000';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(updateMessageProvider);
    
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Update icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: NeoColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  size: 60,
                  color: NeoColors.warning,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Actualización Requerida',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: NeoColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Message from server
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: NeoColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Version info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: NeoColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tu versión: ${EnvConfig.fullVersion}',
                  style: const TextStyle(
                    color: NeoColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openStore(context),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Actualizar App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeoColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _openStore(BuildContext context) async {
    // Detect platform and open appropriate store
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final url = Uri.parse(isIOS ? _appStoreUrl : _playStoreUrl);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Failed to open store
    }
  }
}
