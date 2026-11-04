import 'dart:async';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bamako_thrift/core/constants/feature_flags.dart';
import 'package:bamako_thrift/core/constants/mali_cities.dart';
import 'package:bamako_thrift/core/dependency_injection/injection.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/core/services/logger_service.dart';
import 'package:bamako_thrift/core/services/storage_service.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/features/product/domain/entities/product_entity.dart';
import 'package:bamako_thrift/features/product/data/models/product_model.dart';
import 'package:bamako_thrift/features/product/presentation/cubit/product_cubit.dart';
import 'package:bamako_thrift/shared/widgets/bottom_navigation.dart';
import 'package:bamako_thrift/shared/widgets/sheet_picker_field.dart';

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

  ProductCategory _selectedCategory = ProductCategory.femme;
  // Sous-categorie (ex. "Haut", "Chaussures"...) -- refonte categories du
  // 2026-11-04. null tant que la categorie n'a pas de sous-categorie
  // (Objets) ou que le vendeur n'a pas encore choisi.
  String? _selectedSubCategory;
  ProductCondition _selectedCondition = ProductCondition.bon;

  // ── Menus deroulants marque/taille/couleur (retour de test Fatou,
  // 2026-10-29) : remplace la saisie libre. La valeur finale reste stockee
  // dans les memes controllers qu'avant (_marqueController, etc.) --
  // "Autre" reutilise directement le meme controller comme champ texte.
  static const _kAutre = 'Autre';
  String? _selectedBrandOption;
  String? _selectedSizeOption;
  String? _selectedColorOption;

  static const List<String> _brandOptions = [
    'Sans marque', 'Fait main / Couture', 'Vlisco', 'Woodin', 'Uniwax',
    'Zara', 'H&M', 'Shein', 'Mango', 'Primark', 'Bershka', 'Pull&Bear',
    'Nike', 'Adidas', 'Puma', 'Lacoste', 'Tommy Hilfiger', 'Ralph Lauren',
    'Calvin Klein', "Levi's", _kAutre,
  ];

  static const List<String> _colorOptions = [
    'Noir', 'Blanc', 'Gris', 'Beige', 'Marron', 'Rouge', 'Rose', 'Orange',
    'Jaune', 'Vert', 'Bleu', 'Bleu ciel', 'Violet', 'Doré', 'Argenté',
    'Multicolore', _kAutre,
  ];

  static const List<String> _clothingSizes = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 'Taille unique', _kAutre,
  ];
  static const List<String> _childrenSizes = [
    '0-6 mois', '6-12 mois', '1-2 ans', '3-4 ans', '5-6 ans', '7-8 ans',
    '9-10 ans', '11-12 ans', '13-14 ans', _kAutre,
  ];
  static final List<String> _shoeSizes = [
    for (var p = 35; p <= 46; p++) '$p',
    _kAutre,
  ];

  // null = champ taille masque (categorie/sous-categorie sans notion de
  // taille). Depend desormais de la sous-categorie (refonte 2026-11-04) :
  // "Chaussures" demande une pointure quelle que soit la categorie parente,
  // "Sacs"/"Accessoires" n'ont pas de taille.
  List<String>? _sizeOptionsFor(ProductCategory cat, String? subCat) {
    if (cat == ProductCategory.objets || cat == ProductCategory.beaute) {
      return null;
    }
    if (subCat == 'Chaussures') return _shoeSizes;
    if (subCat == 'Sacs' || subCat == 'Accessoires') return null;
    if (cat == ProductCategory.enfant) return _childrenSizes;
    return _clothingSizes;
  }
  // Ville du vendeur, demandée ici seulement si absente de son profil
  // (lot 6) — enregistrée sur le profil en plus d'être copiée sur
  // l'article (sellerCity).
  String? _selectedSellerCity;
  bool _pressingRequested = false;
  // Autoriser les offres de prix sur cet article (lot "offres"). Défaut
  // autorisé, cohérent avec ProductEntity.offersEnabled.
  bool _offersEnabled = true;

  // XFile (pas dart:io.File) : readAsBytes() marche sur Android/iOS/web,
  // contrairement à File qui n'existe pas vraiment sur le web (lot "putFile
  // web", 2026-10-15 — putFile()/File jetaient UnimplementedError sur le
  // canal web).
  final List<XFile> _selectedImages = [];
  bool _isPublishing = false;
  double _uploadProgress = 0.0;
  String _publishStep = '';

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

  // Choix de la source des photos : appareil photo ou galerie.
  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter une photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.camera_alt,
                    color: Theme.of(ctx).colorScheme.primary),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library,
                    color: Theme.of(ctx).colorScheme.primary),
                title: const Text('Choisir dans la galerie'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final remaining = 5 - _selectedImages.length;
    if (remaining <= 0) return;

    final source = await _chooseImageSource();
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    try {
      if (source == ImageSource.camera) {
        final photo = await picker.pickImage(
            source: ImageSource.camera, imageQuality: 75);
        if (photo != null && mounted) {
          setState(() => _selectedImages.add(photo));
        }
        return;
      }

      // pickMultiImage exige une limite d'au moins 2 : s'il ne reste qu'une
      // place, on choisit une seule photo.
      final List<XFile> picked;
      if (remaining == 1) {
        final one = await picker.pickImage(
            source: ImageSource.gallery, imageQuality: 75);
        picked = one == null ? <XFile>[] : [one];
      } else {
        picked =
            await picker.pickMultiImage(imageQuality: 75, limit: remaining);
      }
      if (picked.isNotEmpty && mounted) {
        setState(() => _selectedImages.addAll(picked.take(remaining)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Impossible d\'ajouter la photo. Vérifie l\'autorisation de l\'appareil photo ou de la galerie.')),
      );
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

    // Ville obligatoire si absente du profil (lot 6) — le sélecteur n'est
    // affiché dans le formulaire que dans ce cas précis, voir build().
    final needsCitySelection = authState.user.city == null;
    if (needsCitySelection && _selectedSellerCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis ta ville')),
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
      final sellerCity = user.city ?? _selectedSellerCity;

      // Vendeur sans ville sur son profil : on l'enregistre aussi là-bas
      // (pas seulement sur cet article, déjà renseigné directement via
      // sellerCity ci-dessous), pour ne plus la redemander la prochaine
      // fois. Indépendant du reste de la publication : part en
      // arrière-plan plutôt que d'être attendu ici (AuthCubit.updateProfile
      // est déjà optimiste côté affichage).
      if (needsCitySelection && _selectedSellerCity != null) {
        // ignore: unawaited_futures
        context.read<AuthCubit>().updateProfile(city: _selectedSellerCity);
      }

      List<String> imageUrls = [];

      if (_selectedImages.isNotEmpty) {
        final storageService = sl<StorageService>();
        final total = _selectedImages.length;

        try {
          for (int i = 0; i < total; i++) {
            if (mounted) {
              setState(() => _publishStep = 'Envoi photo ${i + 1}/$total...');
            }
            // Délai max : sans ça, un envoi qui ne progresse jamais (ex.
            // bucket Storage indisponible) laisse le dialogue bloqué à 0%
            // indéfiniment, sans erreur visible (constaté en test réel sur
            // le canal web, 2026-10-16).
            final url = await storageService
                .uploadProductImage(
                  _selectedImages[i],
                  onProgress: (p) {
                    if (mounted) {
                      setState(() => _uploadProgress = (i + p) / total * 0.8);
                    }
                  },
                )
                .timeout(const Duration(seconds: 60));
            imageUrls.add(url);
          }
        } catch (e) {
          // Jamais le message technique brut à l'écran — journalisé pour
          // debug (code Firebase/Supabase si disponible), message simple
          // affiché. Photo ni décodable ni dans un format accepté (ex.
          // HEIC) : message dédié, distinct d'un échec réseau.
          final isUnsupportedImage = e is UnsupportedImageException;
          final code = e is FirebaseException ? e.code : e.runtimeType.toString();
          logger.severe('Échec envoi photo à la publication',
              error: '$code — ${e.toString()}');
          if (mounted) {
            setState(() => _isPublishing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isUnsupportedImage
                    ? 'Cette photo n\'est pas compatible. Choisis une photo JPG ou PNG.'
                    : 'L\'envoi de la photo a échoué. Vérifie ta connexion et réessaie.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
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
        sellerCity: sellerCity,
        title: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_prixController.text.replaceAll(' ', '')),
        imageUrls: imageUrls,
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
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
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _pressingRequested
                        ? 'Article envoyé au pressing — en cours de vérification !'
                        : 'Article publié avec succès !',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
    final authState = context.watch<AuthCubit>().state;
    final sellerHasNoCity =
        authState is AuthAuthenticated && authState.user.city == null;

    return TabRootBackHandler(
      canRedirectHome: !_isPublishing,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: _isPublishing ? null : () => context.go(RouteNames.home),
          ),
          title: Text(
            'Publier un article',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold),
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
                          style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.black87),
                          decoration: _inputDeco('Ex: Robe longue bleue Zara'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Le titre est requis'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('Catégorie *'),
                        const SizedBox(height: 8),
                        SheetPickerField<ProductCategory>(
                          label: 'Catégorie',
                          value: _selectedCategory,
                          options: selectableProductCategories,
                          labelOf: (c) => c.label,
                          onChanged: (v) => setState(() {
                            _selectedCategory = v!;
                            // Reinitialise sous-categorie et taille au
                            // changement de categorie (options differentes
                            // selon vetements/enfants/objets/beaute).
                            _selectedSubCategory = null;
                            _selectedSizeOption = null;
                            _tailleController.clear();
                          }),
                        ),
                        if (subCategoriesFor(_selectedCategory).isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _sectionTitle('Sous-catégorie'),
                          const SizedBox(height: 8),
                          SheetPickerField<String>(
                            label: 'Sous-catégorie',
                            value: _selectedSubCategory,
                            options: subCategoriesFor(_selectedCategory),
                            labelOf: (s) => s,
                            onChanged: (v) => setState(() {
                              _selectedSubCategory = v;
                              _selectedSizeOption = null;
                              _tailleController.clear();
                            }),
                          ),
                        ],
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
                          style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.black87),
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
                          style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.black87),
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
                        _dropdownWithOther(
                          label: 'Marque',
                          options: _brandOptions,
                          selected: _selectedBrandOption,
                          onSelected: (v) =>
                              setState(() => _selectedBrandOption = v),
                          controller: _marqueController,
                          otherHint: 'Précise la marque (40 caractères max)',
                        ),
                        if (_sizeOptionsFor(_selectedCategory, _selectedSubCategory) != null) ...[
                          const SizedBox(height: 18),
                          _dropdownWithOther(
                            label: 'Taille',
                            options: _sizeOptionsFor(_selectedCategory, _selectedSubCategory)!,
                            selected: _selectedSizeOption,
                            onSelected: (v) =>
                                setState(() => _selectedSizeOption = v),
                            controller: _tailleController,
                            otherHint: 'Précise la taille (40 caractères max)',
                          ),
                        ],
                        const SizedBox(height: 18),
                        _dropdownWithOther(
                          label: 'Couleur',
                          options: _colorOptions,
                          selected: _selectedColorOption,
                          onSelected: (v) =>
                              setState(() => _selectedColorOption = v),
                          controller: _couleurController,
                          otherHint: 'Précise la couleur (40 caractères max)',
                        ),
                        if (sellerHasNoCity) ...[
                          const SizedBox(height: 18),
                          SheetPickerField<String>(
                            label: 'Ta ville',
                            hint: 'Dans quelle ville te trouves-tu ?',
                            value: _selectedSellerCity,
                            options: maliCities,
                            labelOf: (c) => c,
                            onChanged: (v) =>
                                setState(() => _selectedSellerCity = v),
                            validator: (v) =>
                                v == null ? 'Choisis ta ville' : null,
                          ),
                        ],
                        const SizedBox(height: 18),
                        _sectionTitle('Localisation'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _localisationController,
                          style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.black87),
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
                    child: Builder(builder: (context) {
                      final colorScheme = Theme.of(context).colorScheme;
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.surfaceContainerHighest
                              : Colors.white,
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
                                color: colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: _uploadProgress >= 1.0
                                  ? Icon(Icons.check_circle,
                                      color: colorScheme.primary, size: 36)
                                  : CircularProgressIndicator(
                                      color: colorScheme.primary, strokeWidth: 3),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _publishStep,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: isDark
                                    ? colorScheme.surfaceContainerHighest
                                    : Colors.grey.shade200,
                                color: colorScheme.primary,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedImages.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${_selectedImages.length} photo(s)',
                                style: TextStyle(
                                    color: isDark
                                        ? colorScheme.onSurfaceVariant
                                        : Colors.grey,
                                    fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Colors.white,
                border: Border(
                  top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.outlineVariant
                          : Colors.grey.shade200),
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        disabledBackgroundColor:
                            Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isPublishing
                          ? CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeWidth: 2)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rocket_launch_outlined,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Je publie',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        if (_selectedImages.isEmpty)
          GestureDetector(
            onTap: _isPublishing ? null : _pickImages,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: colorScheme.primary,
              ),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.primary.withOpacity(0.1)
                      : const Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: colorScheme.primary.withOpacity(0.6),
                      size: 32,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Ajouter photos',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Max 5 photos',
                      style: TextStyle(
                          color: isDark ? colorScheme.onSurfaceVariant : Colors.grey,
                          fontSize: 12),
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
                        color: isDark
                            ? colorScheme.primary.withOpacity(0.1)
                            : const Color(0xFFF7F4EE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              color: colorScheme.primary, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedImages.length}/5',
                            style: TextStyle(
                              color: colorScheme.primary,
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
                            // XFile.path est un blob: URL sur le web
                            // (chargeable via NetworkImage), un vrai chemin
                            // de fichier sur Android/iOS (FileImage).
                            image: kIsWeb
                                ? NetworkImage(file.path) as ImageProvider
                                : FileImage(File(file.path)),
                            fit: BoxFit.cover,
                          ),
                          border: idx == 0
                              ? Border.all(color: colorScheme.primary, width: 2.5)
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
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Principale',
                              style:
                                  TextStyle(color: colorScheme.onPrimary, fontSize: 8),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isSelected
                  ? colorScheme.primary
                  : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : (isDark ? colorScheme.outlineVariant : Colors.grey.shade300),
              ),
            ),
            child: Text(
              c['label'] as String,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : (isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade700),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    color: isDark
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Colors.grey,
                    fontSize: 12)),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface),
      );

  InputDecoration _inputDeco(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: isDark ? colorScheme.onSurfaceVariant : Colors.grey,
          fontSize: 13),
      filled: true,
      fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }

  // ── Menu deroulant avec option "Autre" (champ texte, 40 car. max,
  // obligatoire si choisie) — marque/taille/couleur. La valeur finale reste
  // ecrite dans [controller], que l'option vienne de la liste ou du texte
  // libre "Autre".
  Widget _dropdownWithOther({
    required String label,
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
    required TextEditingController controller,
    String otherHint = 'Précise ici (40 caractères max)',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetPickerField<String>(
          label: label,
          hint: 'Choisis une option',
          value: selected,
          options: options,
          labelOf: (o) => o,
          onChanged: (v) {
            onSelected(v);
            controller.text = (v == null || v == _kAutre) ? '' : v;
          },
        ),
        if (selected == _kAutre) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLength: 40,
            style: TextStyle(
                color: isDark
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.black87),
            decoration: _inputDeco(otherHint),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Précise $label'
                : null,
          ),
        ],
      ],
    );
  }

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
            activeThumbColor: colors.primary,
            onChanged: (v) => setState(() => _offersEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPressingOption() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _pressingRequested
              ? colorScheme.primary
              : (isDark ? colorScheme.outlineVariant : Colors.grey.shade300),
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
              activeColor: colorScheme.primary,
              onChanged: (v) =>
                  setState(() => _pressingRequested = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faire vérifier / remettre à neuf mon article via notre partenaire pressing',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pressingRequested
                          ? 'Ton article sera visible après vérification et affichera le badge « Vérifié ».'
                          : 'Optionnel. Ton article reste publié directement, comme aujourd\'hui.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade600,
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
