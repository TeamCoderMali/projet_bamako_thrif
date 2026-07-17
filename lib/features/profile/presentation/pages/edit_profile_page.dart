import 'dart:io';
import 'package:bamako_thrift/core/dependency_injection/injection.dart';
import 'package:bamako_thrift/core/services/storage_service.dart';
import 'package:bamako_thrift/features/auth/domain/entities/user_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  bool _initialized = false;

  // Avatar
  File? _selectedAvatar; // fichier local sélectionné
  bool _isUploadingAvatar = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = context.read<AuthCubit>().state;
      final user = state is AuthAuthenticated ? state.user : null;
      _nomController = TextEditingController(text: user?.fullName ?? '');
      _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
      _bioController = TextEditingController(text: user?.bio ?? '');
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Sélectionner et uploader l'avatar ────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    setState(() {
      _selectedAvatar = file;
      _isUploadingAvatar = true;
    });

    try {
      final storageService = sl<StorageService>();
      final avatarUrl = await storageService.uploadAvatar(file);

      // Mettre à jour Firestore avec la nouvelle URL d'avatar
      await context.read<AuthCubit>().updateProfile(avatarUrl: avatarUrl);

      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Photo de profil mise à jour !'),
              ],
            ),
            backgroundColor: const Color(0xFF6B7F4D),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAvatar = null;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choisir une photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7F4D).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Color(0xFF6B7F4D)),
                ),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Choisir dans la galerie'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sauvegarder les infos du profil ──────────────────────────────────────
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    try {
      final success = await context.read<AuthCubit>().updateProfile(
            fullName: _nomController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Profil mis à jour avec succès !'),
                ],
              ),
              backgroundColor: const Color(0xFF6B7F4D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          context.go(RouteNames.profile);
        } else {
          final state = context.read<AuthCubit>().state;
          final msg =
              state is AuthError ? state.message : 'Erreur de mise à jour';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final isLoading = state is AuthLoading || _isSaving;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (isLoading || _isUploadingAvatar)
                  ? null
                  : () => context.go(RouteNames.profile),
            ),
            title: const Text(
              'Modifier le profil',
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: (isLoading || _isUploadingAvatar) ? null : _save,
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(
                    color: Color(0xFF6B7F4D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ── Avatar avec upload ──────────────────────────────────
                  Center(
                    child: Stack(
                      children: [
                        // Photo de profil
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF6B7F4D),
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: _buildAvatar(user),
                          ),
                        ),

                        // Overlay de chargement pendant l'upload
                        if (_isUploadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Bouton appareil photo
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: _isUploadingAvatar
                                ? null
                                : _pickAndUploadAvatar,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _isUploadingAvatar
                                    ? Colors.grey
                                    : const Color(0xFF6B7F4D),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    _isUploadingAvatar
                        ? 'Envoi en cours...'
                        : 'Appuyez pour changer la photo',
                    style: TextStyle(
                      color: _isUploadingAvatar
                          ? const Color(0xFF6B7F4D)
                          : Colors.grey,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Email (lecture seule) ───────────────────────────────
                  TextFormField(
                    initialValue: user?.email ?? '',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.lock_outline,
                          size: 16, color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // ── Nom complet ────────────────────────────────────────
                  TextFormField(
                    controller: _nomController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF6B7F4D), width: 1.5),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Le nom est requis'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Téléphone ──────────────────────────────────────────
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      hintText: '+223 70 00 00 00',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF6B7F4D), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Bio ────────────────────────────────────────────────
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 150,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Parlez un peu de vous...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.info_outline),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF6B7F4D), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Bouton sauvegarder ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (isLoading || _isUploadingAvatar)
                          ? null
                          : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7F4D),
                        disabledBackgroundColor:
                            const Color(0xFF6B7F4D).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Text(
                              'Sauvegarder les modifications',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Afficher l'avatar : local d'abord, puis Firestore, puis initiales ────
  Widget _buildAvatar(UserEntity? user) {
    if (_selectedAvatar != null) {
      return Image.file(_selectedAvatar!, fit: BoxFit.cover,
          width: 100, height: 100);
    }
    if (user?.avatarUrl != null) {
      return CachedNetworkImage(
        imageUrl: user!.avatarUrl!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        placeholder: (_, __) => Container(
          color: const Color(0xFF6B7F4D).withOpacity(0.1),
          child: const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF6B7F4D), strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => _initialsWidget(user),
      );
    }
    return _initialsWidget(user);
  }

  Widget _initialsWidget(UserEntity? user) {
    return Container(
      color: const Color(0xFF6B7F4D),
      width: 100,
      height: 100,
      child: Center(
        child: Text(
          user?.initials ?? '?',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
