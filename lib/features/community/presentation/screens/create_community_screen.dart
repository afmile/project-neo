/// Project Neo - Amino-Style Community Creation Wizard
///
/// Immersive 6-step wizard for founding new communities.
/// Steps: Type → Identity → Icon → Theme → Privacy → Loading
library;

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_entity.dart';
import '../providers/community_providers.dart';
import 'community_home_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// COMMUNITY TYPE DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════

enum CommunityType {
  amigos(
    icon: '👥',
    title: 'Amigos',
    description: 'Para grupos de amigos cercanos',
    color: Color(0xFF3B82F6),
    modules: {'chat': true, 'posts': true, 'wiki': false, 'polls': true, 'rankings': false},
  ),
  rol(
    icon: '🎭',
    title: 'Rol',
    description: 'Juegos de rol y narrativas',
    color: Color(0xFF8B5CF6),
    modules: {'chat': true, 'posts': true, 'wiki': true, 'polls': true, 'rankings': true},
  ),
  gamers(
    icon: '🎮',
    title: 'Gamers',
    description: 'Para comunidades gaming',
    color: Color(0xFF10B981),
    modules: {'chat': true, 'posts': true, 'wiki': true, 'polls': true, 'rankings': true},
  ),
  arte(
    icon: '🎨',
    title: 'Arte',
    description: 'Artistas y creativos',
    color: Color(0xFFEC4899),
    modules: {'chat': true, 'posts': true, 'wiki': true, 'polls': false, 'rankings': false},
  ),
  custom(
    icon: '⚙️',
    title: 'Personalizado',
    description: 'Configura todo desde cero',
    color: Color(0xFFF59E0B),
    modules: {'chat': false, 'posts': false, 'wiki': false, 'polls': false, 'rankings': false},
  );

  final String icon;
  final String title;
  final String description;
  final Color color;
  final Map<String, bool> modules;

  const CommunityType({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.modules,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// PRIVACY OPTIONS
// ═══════════════════════════════════════════════════════════════════════════

enum PrivacyOption {
  open(
    icon: Icons.public,
    title: 'Abierta',
    description: 'Cualquiera puede unirse',
  ),
  approval(
    icon: Icons.how_to_reg,
    title: 'Aprobación',
    description: 'Requiere aprobación para unirse',
  ),
  private(
    icon: Icons.lock,
    title: 'Privada',
    description: 'Solo por invitación',
  );

  final IconData icon;
  final String title;
  final String description;

  const PrivacyOption({
    required this.icon,
    required this.title,
    required this.description,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN WIZARD SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class CommunityWizardScreen extends ConsumerStatefulWidget {
  const CommunityWizardScreen({super.key});

  @override
  ConsumerState<CommunityWizardScreen> createState() => _CommunityWizardScreenState();
}

class _CommunityWizardScreenState extends ConsumerState<CommunityWizardScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 6;
  
  // Wizard State
  CommunityType? _selectedType;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _language = 'es';
  File? _iconFile;
  Color _accentColor = NeoColors.accent;
  PrivacyOption _privacy = PrivacyOption.open;
  bool _acceptedTerms = false;
  bool _isCreating = false;
  
  late AnimationController _progressController;
  
  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _progressController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NeoTheme.darkTheme(accentColor: _accentColor),
      child: Scaffold(
        backgroundColor: NeoColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                    _progressController.animateTo(index / (_totalSteps - 1));
                  },
                  children: [
                    _buildStepType(),
                    _buildStepIdentity(),
                    _buildStepIcon(),
                    _buildStepTheme(),
                    _buildStepPrivacy(),
                    _buildStepLoading(),
                  ],
                ),
              ),
              if (_currentStep < 5) _buildNavigation(),
            ],
          ),
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER & PROGRESS
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildHeader() {
    final stepTitles = ['Tipo', 'Identidad', 'Icono', 'Tema', 'Privacidad', 'Creando...'];
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Close Button
          _buildGlowButton(
            icon: Icons.close,
            onTap: () => _showExitConfirmation(),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear Neo',
                  style: NeoTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stepTitles[_currentStep],
                  style: NeoTextStyles.bodySmall.copyWith(
                    color: _accentColor,
                  ),
                ),
              ],
            ),
          ),
          // Step Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentStep + 1}/$_totalSteps',
              style: NeoTextStyles.labelMedium.copyWith(color: _accentColor),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGlowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: NeoColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeoColors.border),
        ),
        child: Icon(icon, color: NeoColors.textSecondary, size: 20),
      ),
    );
  }
  
  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 4,
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * ((_currentStep + 1) / _totalSteps),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accentColor, _accentColor.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP A: TYPE SELECTION
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildStepType() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            '¿Qué tipo de Neo\nquieres crear?',
            style: NeoTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esto pre-configura los módulos ideales',
            style: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.textSecondary),
          ),
          const SizedBox(height: 32),
          
          // Type Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: CommunityType.values.length,
            itemBuilder: (context, index) {
              final type = CommunityType.values[index];
              final isSelected = _selectedType == type;
              
              return _TypeCard(
                type: type,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedType = type);
                  HapticFeedback.selectionClick();
                },
              ).animate(delay: (index * 80).ms).fadeIn().scale(
                begin: const Offset(0.9, 0.9),
                duration: 300.ms,
                curve: Curves.easeOutBack,
              );
            },
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP B: IDENTITY
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildStepIdentity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Dale una identidad',
            style: NeoTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Name Input
          _NeoTextField(
            controller: _nameController,
            label: 'Nombre',
            hint: 'Mi Comunidad Épica',
            maxLength: 30,
            accentColor: _accentColor,
          ),
          const SizedBox(height: 24),
          
          // Description Input
          _NeoTextField(
            controller: _descriptionController,
            label: 'Descripción corta',
            hint: '¿De qué trata tu comunidad?',
            maxLength: 80,
            maxLines: 2,
            accentColor: _accentColor,
          ),
          const SizedBox(height: 24),
          
          // Language Dropdown
          Text(
            'Idioma principal',
            style: NeoTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          _LanguageSelector(
            value: _language,
            onChanged: (value) => setState(() => _language = value),
            accentColor: _accentColor,
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP C: ICON
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildStepIcon() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            'Elige un icono',
            style: NeoTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Esta será la cara de tu comunidad',
            style: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Icon Upload Button
          GestureDetector(
            onTap: _pickIcon,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: NeoColors.card,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _iconFile != null ? _accentColor : NeoColors.border,
                  width: _iconFile != null ? 3 : 2,
                ),
                boxShadow: _iconFile != null ? [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ] : null,
                image: _iconFile != null
                    ? DecorationImage(
                        image: FileImage(_iconFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _iconFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: _accentColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Subir imagen',
                          style: NeoTextStyles.labelMedium.copyWith(
                            color: _accentColor,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          
          const SizedBox(height: 24),
          
          // Skip text
          TextButton(
            onPressed: _nextStep,
            child: Text(
              'Omitir por ahora',
              style: NeoTextStyles.bodySmall.copyWith(
                color: NeoColors.textTertiary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          
          const Spacer(flex: 2),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP D: THEME
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildStepTheme() {
    final colors = [
      const Color(0xFF5865F2), // Discord Blue (default)
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Green
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF3B82F6), // Blue
    ];
    
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            _accentColor.withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Elige tu color',
              style: NeoTextStyles.displaySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Define la personalidad visual',
              style: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.textSecondary),
            ),
            const SizedBox(height: 48),
            
            // Color Grid
            Center(
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: colors.asMap().entries.map((entry) {
                  final color = entry.value;
                  final isSelected = _accentColor.value == color.value;
                  
                  return _ColorOrb(
                    color: color,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _accentColor = color);
                      HapticFeedback.selectionClick();
                    },
                  ).animate(delay: (entry.key * 50).ms).scale(
                    begin: const Offset(0, 0),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Preview Card
            Text(
              'Vista Previa',
              style: NeoTextStyles.labelMedium.copyWith(color: NeoColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _PreviewCard(
              name: _nameController.text.isEmpty ? 'Tu Comunidad' : _nameController.text,
              description: _descriptionController.text.isEmpty 
                  ? 'Una comunidad increíble' 
                  : _descriptionController.text,
              accentColor: _accentColor,
              iconFile: _iconFile,
              type: _selectedType,
            ),
          ],
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP E: PRIVACY
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildStepPrivacy() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            '¿Quién puede unirse?',
            style: NeoTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Privacy Options
          ...PrivacyOption.values.asMap().entries.map((entry) {
            final option = entry.value;
            final isSelected = _privacy == option;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PrivacyCard(
                option: option,
                isSelected: isSelected,
                accentColor: _accentColor,
                onTap: () {
                  setState(() => _privacy = option);
                  HapticFeedback.selectionClick();
                },
              ).animate(delay: (entry.key * 100).ms).fadeIn().slideX(
                begin: 0.1,
                duration: 300.ms,
                curve: Curves.easeOut,
              ),
            );
          }),
          
          const SizedBox(height: 32),
          
          // Terms Checkbox
          GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NeoColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _acceptedTerms ? _accentColor : NeoColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _acceptedTerms ? _accentColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _acceptedTerms ? _accentColor : NeoColors.textTertiary,
                      ),
                    ),
                    child: _acceptedTerms
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Acepto los Términos y Condiciones de Project Neo',
                      style: NeoTextStyles.bodyMedium.copyWith(
                        color: _acceptedTerms ? Colors.white : NeoColors.textSecondary,
                      ),
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
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP F: LOADING / CREATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildStepLoading() {
    return _CreationLoadingScreen(
      accentColor: _accentColor,
      onComplete: _onCommunityCreated,
      createCommunity: _performCreation,
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildNavigation() {
    final canProceed = _canProceedFromCurrentStep();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NeoColors.surface,
        border: Border(top: BorderSide(color: NeoColors.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: NeoColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Atrás', style: TextStyle(color: NeoColors.textSecondary)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: canProceed ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                disabledBackgroundColor: NeoColors.card,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == 4 ? 'Crear Neo' : 'Siguiente',
                    style: NeoTextStyles.button.copyWith(
                      color: canProceed ? Colors.white : NeoColors.textTertiary,
                    ),
                  ),
                  if (_currentStep < 4) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: canProceed ? Colors.white : NeoColors.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  bool _canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0: return _selectedType != null;
      case 1: return _nameController.text.length >= 3;
      case 2: return true; // Icon is optional
      case 3: return true; // Color is pre-selected
      case 4: return _acceptedTerms;
      default: return false;
    }
  }
  
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }
  
  Future<CommunityEntity?> _performCreation() async {
    final repository = ref.read(communityRepositoryProvider);
    
    final theme = CommunityTheme(
      primaryColor: '#${_accentColor.value.toRadixString(16).substring(2)}',
      secondaryColor: '#${_accentColor.withOpacity(0.7).value.toRadixString(16).substring(2)}',
      accentColor: '#${_accentColor.value.toRadixString(16).substring(2)}',
    );
    
    String slug = _nameController.text.trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    
    // Add random suffix for uniqueness
    slug = '$slug-${DateTime.now().millisecondsSinceEpoch % 10000}';
    
    final result = await repository.createCommunity(
      title: _nameController.text.trim(),
      slug: slug,
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      theme: theme,
      isPrivate: _privacy == PrivacyOption.private,
    );
    
    return result.fold(
      (failure) => null,
      (community) async {
        // Upload icon if provided
        if (_iconFile != null) {
          await repository.uploadCommunityImage(
            communityId: community.id,
            imageFile: _iconFile!,
            imageType: 'icon',
          );
        }
        
        ref.invalidate(userCommunitiesProvider);
        return community;
      },
    );
  }
  
  void _onCommunityCreated(CommunityEntity community) {
    // Navigate to new community where owner can see Neo Studio button
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CommunityHomeScreen(community: community),
      ),
    );
  }
  
  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() => _iconFile = File(image.path));
    }
  }
  
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeoColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Salir del wizard?', style: NeoTextStyles.headlineMedium),
        content: Text(
          'Perderás el progreso actual.',
          style: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: NeoColors.error),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _TypeCard extends StatelessWidget {
  final CommunityType type;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _TypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? type.color.withOpacity(0.15) : NeoColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? type.color : NeoColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: type.color.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(type.icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              type.title,
              style: NeoTextStyles.labelLarge.copyWith(
                color: isSelected ? type.color : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                type.description,
                style: NeoTextStyles.bodySmall.copyWith(
                  color: NeoColors.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLength;
  final int maxLines;
  final Color accentColor;
  
  const _NeoTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLength,
    this.maxLines = 1,
    required this.accentColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: NeoTextStyles.labelLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          style: NeoTextStyles.bodyLarge.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: NeoTextStyles.bodyLarge.copyWith(color: NeoColors.textTertiary),
            filled: true,
            fillColor: NeoColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: NeoColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: NeoColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            counterStyle: NeoTextStyles.bodySmall.copyWith(color: NeoColors.textTertiary),
          ),
        ),
      ],
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final Color accentColor;
  
  const _LanguageSelector({
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final languages = [
      ('es', '🇪🇸 Español'),
      ('en', '🇺🇸 English'),
      ('pt', '🇧🇷 Português'),
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeoColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: NeoColors.elevated,
          icon: Icon(Icons.keyboard_arrow_down, color: accentColor),
          items: languages.map((lang) => DropdownMenuItem(
            value: lang.$1,
            child: Text(lang.$2, style: NeoTextStyles.bodyLarge.copyWith(color: Colors.white)),
          )).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }
}

class _ColorOrb extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _ColorOrb({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 64 : 56,
        height: isSelected ? 64 : 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isSelected ? 0.6 : 0.3),
              blurRadius: isSelected ? 16 : 8,
              spreadRadius: isSelected ? 4 : 0,
            ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 28)
            : null,
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final PrivacyOption option;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  
  const _PrivacyCard({
    required this.option,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : NeoColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : NeoColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : NeoColors.elevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(option.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: NeoTextStyles.labelLarge.copyWith(
                      color: isSelected ? accentColor : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: NeoTextStyles.bodySmall.copyWith(
                      color: NeoColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: accentColor, size: 24),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String name;
  final String description;
  final Color accentColor;
  final File? iconFile;
  final CommunityType? type;
  
  const _PreviewCard({
    required this.name,
    required this.description,
    required this.accentColor,
    this.iconFile,
    this.type,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(12),
              image: iconFile != null
                  ? DecorationImage(
                      image: FileImage(iconFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: iconFile == null
                ? Center(
                    child: Text(
                      type?.icon ?? '✨',
                      style: const TextStyle(fontSize: 24),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: NeoTextStyles.labelLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: NeoTextStyles.bodySmall.copyWith(color: NeoColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Unirse',
              style: NeoTextStyles.labelSmall.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class _CreationLoadingScreen extends StatefulWidget {
  final Color accentColor;
  final Function(CommunityEntity) onComplete;
  final Future<CommunityEntity?> Function() createCommunity;
  
  const _CreationLoadingScreen({
    required this.accentColor,
    required this.onComplete,
    required this.createCommunity,
  });
  
  @override
  State<_CreationLoadingScreen> createState() => _CreationLoadingScreenState();
}

class _CreationLoadingScreenState extends State<_CreationLoadingScreen> {
  int _messageIndex = 0;
  bool _hasError = false;
  Timer? _messageTimer;
  
  final _messages = [
    'Configurando servidores...',
    'Creando base de datos...',
    'Aplicando tema...',
    'Preparando módulos...',
    'Casi listo...',
  ];
  
  @override
  void initState() {
    super.initState();
    _startCreation();
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _messageIndex < _messages.length - 1) {
        setState(() => _messageIndex++);
      }
    });
  }
  
  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _startCreation() async {
    final community = await widget.createCommunity();
    
    _messageTimer?.cancel();
    
    if (community != null && mounted) {
      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onComplete(community);
    } else if (mounted) {
      setState(() => _hasError = true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: NeoColors.error),
            const SizedBox(height: 16),
            Text(
              'Error al crear la comunidad',
              style: NeoTextStyles.headlineSmall.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [widget.accentColor, widget.accentColor.withOpacity(0.5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch, color: Colors.white, size: 48),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 1500.ms,
            color: Colors.white.withOpacity(0.3),
          ),
          
          const SizedBox(height: 48),
          
          // Message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _messages[_messageIndex],
              key: ValueKey(_messageIndex),
              style: NeoTextStyles.headlineSmall.copyWith(color: Colors.white),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Progress indicator
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: NeoColors.card,
              valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
            ),
          ),
        ],
      ),
    );
  }
}
