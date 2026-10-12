import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bamako_thrift/core/constants/feature_flags.dart';
import 'package:bamako_thrift/core/dependency_injection/injection.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/core/services/storage_service.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/features/product/domain/entities/product_entity.dart';
import 'package:bamako_thrift/features/product/data/models/product_model.dart';
import 'package:bamako_thrift/features/product/presentation/cubit/product_cubit.dart';
import 'package:bamako_thrift/shared/widgets/bottom_navigation.dart';

class PublishProductPage extends StatefulWidget {
  const PublishProductPage({super.key});

  @override
  State<PublishProductPage> createState() => _PublishProductPageState();
}

class _PublishProductPageState extends State<PublishProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  final _marqueController = TextEditingController();
  final _tailleController = TextEditingController();
  final _couleurController = TextEditingController();
  final _localisationController = TextEditingController();

  ProductCategory _selectedCategory = ProductCategory.women;
  ProductCondition _selectedCondition = ProductCondition.bon;
  bool _pressingRequested = false;
  // Autoriser les offres de prix sur cet article (lot "offres"). Défaut
  // autorisé, cohérent avec ProductEntity.offersEnabled.
  bool _offersEnabled = true;

  final List<File> _selectedImages = [];
  bool _isPublishing = false;
  double _uploadProgress = 0.0;
  String _publishStep = '';

  // Liste centralisee (product_entity.dart, lot 2) pour rester synchronisee
  // avec filter_page.dart. "Sacs"/"Bijoux" n'y figurent plus (fusion
  // cosmétique dans Accessoires) : un nouvel article ne peut plus être
  // publié directement sous ces deux catégories, mais les articles
  // existants ne sont pas touchés.
  final List<Map<String, dynamic>> _categories = [
    for (final c in selectableProductCategories) {'label': c.label, 'value': c},
  ];

  // ── 4 états exacts du cahier des charges (section 4.3) ──────────────────
  final List<Map<String, dynamic>> _conditions = [
    for (final c in ProductCondition.values) {'label': c.label, 'value': c},
  ];

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _marqueController.dispose();
    _tailleController.dispose();
    _couleurController.dispose();
    _localisationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
        imageQuality: 75, limit: 5 - _selectedImages.length);
    if (picked.isNotEmpty && mounted) {
      setState(() {
        _selectedImages.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu dois être connecté pour publier')),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
      _uploadProgress = 0.0;
      _publishStep = _selectedImages.isEmpty
          ? 'Création de l\'annonce...'
          : 'Envoi des photos...';
    });

    try {
      final user = authState.user;
      List<String> imageUrls = [];

      if (_selectedImages.isNotEmpty) {
        final storageService = sl<StorageService>();
        final total = _selectedImages.length;

        for (int i = 0; i < total; i++) {
          if (mounted) {
            setState(() => _publishStep = 'Envoi photo ${i + 1}/$total...');
          }
          final url =
              await storageService.uploadProductImage(_selectedImages[i]);
          imageUrls.add(url);
          if (mounted) {
            setState(() => _uploadProgress = (i + 1) / total * 0.8);
          }
        }
      }

      if (mounted) {
        setState(() {
          _publishStep = 'Création de l\'annonce...';
          _uploadProgress = 0.9;
        });
      }

      final product = ProductModel(
        id: '',
        sellerId: user.id,
        sellerName: user.fullName,
        sellerAvatarUrl: user.avatarUrl,
        title: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_prixController.text.replaceAll(' ', '')),
        imageUrls: imageUrls,
        category: _selectedCategory,
        condition: _selectedCondition,
        brand: _marqueController.text.trim().isEmpty
            ? null
            : _marqueController.text.trim(),
        size: _tailleController.text.trim().isEmpty
            ? null
            : _tailleController.text.trim(),
        color: _couleurController.text.trim().isEmpty
            ? null
            : _couleurController.text.trim(),
        location: _localisationController.text.trim().isEmpty
            ? null
            : _localisationController.text.trim(),
        status: _pressingRequested
            ? ProductStatus.enAttenteVerification
            : ProductStatus.available,
        verifie: false,
        offersEnabled: _offersEnabled,
        createdAt: DateTime.now(),
      );

      await context.read<ProductCubit>().createProduct(product);

      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
          _publishStep = 'Publié !';
        });

        await Future.delayed(const Duration(milliseconds: 400));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_pressingRequested
                      ? 'Article envoyé au pressing — en cours de vérification !'
                      : 'Article publié avec succès !'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF6B7F4D),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go(RouteNames.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TabRootBackHandler(
      canRedirectHome: !_isPublishing,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4EE),
        appBar: AppBar(
          backgroundColor: const Color(0xFF6B7F4D),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _isPublishing ? null : () => context.go(RouteNames.home),
          ),
          title: const Text(
            'Publier un article',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _formSection(
                      title: 'Photos (max 5)',
                      subtitle:
                          'Des photos de qualité augmentent tes chances de vente.',
                      children: [_buildImagePicker()],
                    ),
                    _formSection(
                      title: 'Présentation',
                      children: [
                        _sectionTitle('Titre *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titreController,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _inputDeco('Ex: Robe longue bleue Zara'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Le titre est requis'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('Catégorie *'),
                        const SizedBox(height: 8),
                        _dropdownContainer(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ProductCategory>(
                              value: _selectedCategory,
                              isExpanded: true,
                              items: _categories.map((cat) {
                                return DropdownMenuItem<ProductCategory>(
                                  value: cat['value'] as ProductCategory,
                                  child: Text(cat['label'] as String,
                                      style: const TextStyle(
                                          color: Colors.black87)),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCategory = v!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('État du vêtement *'),
                        const SizedBox(height: 8),
                        _buildConditionSelector(),
                        const SizedBox(height: 18),
                        _sectionTitle('Prix en FCFA *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _prixController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _inputDeco('Ex: 5000').copyWith(
                            suffixText: 'FCFA',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Prix requis';
                            }
                            final val = double.tryParse(v.replaceAll(' ', ''));
                            if (val == null || val <= 0) return 'Prix invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('Description *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _inputDeco(
                              'Décris ton article : état, utilisation, taille exacte...'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'La description est requise'
                              : null,
                        ),
                      ],
                    ),
                    _formSection(
                      title: 'Détails',
                      children: [
                        _sectionTitle('Marque'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _marqueController,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _inputDeco('Ex: Zara, Nike, Adidas...'),
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('Taille'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _tailleController,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _inputDeco('Ex: M, 38, 42...'),
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('Couleur'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _couleurController,
                          style: const TextStyle(color: Colors.black87),
                          decoration:
                              _inputDeco('Ex: Bleu marine, Rouge, Noir...'),
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('Localisation'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _localisationController,
                          style: const TextStyle(color: Colors.black87),
                          decoration:
                              _inputDeco('Ex: Bamako, Hamdallaye ACI 2000...'),
                        ),
                        if (pressingEnabled) ...[
                          const SizedBox(height: 18),
                          _buildPressingOption(),
                        ],
                        const SizedBox(height: 18),
                        _buildOffersToggle(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isPublishing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B7F4D).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: _uploadProgress >= 1.0
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF6B7F4D), size: 36)
                                : const CircularProgressIndicator(
                                    color: Color(0xFF6B7F4D), strokeWidth: 3),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _publishStep,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2B2B2B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                              backgroundColor: Colors.grey.shade200,
                              color: const Color(0xFF6B7F4D),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_uploadProgress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFF6B7F4D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedImages.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${_selectedImages.length} photo(s)',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isPublishing ? null : _publish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7F4D),
                        disabledBackgroundColor:
                            const Color(0xFF6B7F4D).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isPublishing
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.rocket_launch_outlined,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Je publie',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Publication gratuite et immédiate',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            AppBottomNav(
              currentIndex: 2,
              enabled: !_isPublishing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_selectedImages.isEmpty)
          GestureDetector(
            onTap: _isPublishing ? null : _pickImages,
            child: CustomPaint(
              painter: const _DashedBorderPainter(
                color: Color(0xFF6B7F4D),
              ),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: const Color(0xFF6B7F4D).withOpacity(0.6),
                      size: 32,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B7F4D),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Ajouter photos',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Max 5 photos',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (_selectedImages.length < 5)
                  GestureDetector(
                    onTap: _isPublishing ? null : _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F4EE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6B7F4D).withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo,
                              color: Color(0xFF6B7F4D), size: 28),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedImages.length}/5',
                            style: const TextStyle(
                              color: Color(0xFF6B7F4D),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ..._selectedImages.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final file = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          ),
                          border: idx == 0
                              ? Border.all(
                                  color: const Color(0xFF6B7F4D), width: 2.5)
                              : null,
                        ),
                      ),
                      if (idx == 0)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B7F4D),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Principale',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 8),
                            ),
                          ),
                        ),
                      if (!_isPublishing)
                        Positioned(
                          top: 2,
                          right: 12,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedImages.removeAt(idx)),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildConditionSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _conditions.map((c) {
        final condition = c['value'] as ProductCondition;
        final isSelected = _selectedCondition == condition;
        return GestureDetector(
          onTap: () => setState(() => _selectedCondition = condition),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6B7F4D) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF6B7F4D) : Colors.grey.shade300,
              ),
            ),
            child: Text(
              c['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _formSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2B2B2B),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF2B2B2B)),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6B7F4D), width: 1.5),
        ),
      );

  Widget _dropdownContainer({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  // ── Option pressing : vérification / remise en état avant publication ────
  // ── Autoriser les offres de prix (lot "offres") ─────────────────────────
  Widget _buildOffersToggle() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Autoriser les offres de prix',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _offersEnabled
                      ? 'Les acheteurs peuvent proposer un prix pour cet article.'
                      : 'Les acheteurs ne pourront pas négocier le prix de cet article.',
                  style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: _offersEnabled,
            activeThumbColor: const Color(0xFF6B7F4D),
            onChanged: (v) => setState(() => _offersEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPressingOption() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _pressingRequested
              ? const Color(0xFF6B7F4D)
              : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            setState(() => _pressingRequested = !_pressingRequested),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _pressingRequested,
              activeColor: const Color(0xFF6B7F4D),
              onChanged: (v) =>
                  setState(() => _pressingRequested = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Faire vérifier / remettre à neuf mon article via notre partenaire pressing',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pressingRequested
                          ? 'Ton article sera visible après vérification et affichera le badge « Vérifié ».'
                          : 'Optionnel. Ton article reste publié directement, comme aujourd\'hui.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bordure pointillée pour la zone photo ───────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.color,
    this.radius = 16,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashedPath.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + dashGap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashGap != dashGap ||
      oldDelegate.strokeWidth != strokeWidth;
}
