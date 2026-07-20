import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import '../../domain/entities/user_entity.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  UserRole _selectedRole = UserRole.buyer;

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await context.read<AuthCubit>().register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nomController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          role: _selectedRole,
        );

    if (mounted) {
      if (success) {
        context.go(RouteNames.home);
      } else {
        final errorMsg = context.read<AuthCubit>().state is AuthError
            ? (context.read<AuthCubit>().state as AuthError).message
            : 'Erreur lors de l\'inscription';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(RouteNames.home);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: const Color(0xFFF7F4EE),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ── Logo ─────────────────────────────────────────────
                    Center(
                      child: Image.asset(
                        'assets/images/logo_danaya.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Titre ─────────────────────────────────────────────
                    const Center(
                      child: Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Rejoins DANAYA',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Nom complet ───────────────────────────────────────
                    TextFormField(
                      controller: _nomController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF2B2B2B)),
                      decoration:
                          _inputDeco('Nom complet *', Icons.person_outline),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Le nom est requis'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // ── Email ─────────────────────────────────────────────
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF2B2B2B)),
                      decoration: _inputDeco('Email *', Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'L\'email est requis';
                        }
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Téléphone ─────────────────────────────────────────
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF2B2B2B)),
                      decoration: _inputDeco(
                          'Téléphone (optionnel)', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 14),

                    // ── Mot de passe ──────────────────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF2B2B2B)),
                      decoration:
                          _inputDeco('Mot de passe *', Icons.lock_outline)
                              .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF6B7F4D),
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Mot de passe requis';
                        }
                        if (v.length < 6) {
                          return 'Au moins 6 caractères requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Confirmer mot de passe ────────────────────────────
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF2B2B2B)),
                      decoration: _inputDeco(
                              'Confirmer le mot de passe *', Icons.lock_outline)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF6B7F4D),
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Confirmation requise'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Rôle ─────────────────────────────────────────────
                    const Text(
                      'Je suis :',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleCard(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Acheteur',
                            subtitle: 'Je cherche des articles',
                            isSelected: _selectedRole == UserRole.buyer,
                            onTap: () =>
                                setState(() => _selectedRole = UserRole.buyer),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleCard(
                            icon: Icons.storefront_outlined,
                            label: 'Vendeur',
                            subtitle: 'Je vends des articles',
                            isSelected: _selectedRole == UserRole.seller,
                            onTap: () =>
                                setState(() => _selectedRole = UserRole.seller),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Bouton S'inscrire ─────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7F4D),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : const Text(
                                "S'inscrire",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Lien Login ────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Déjà un compte ? ',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(RouteNames.login),
                          child: const Text(
                            'Se connecter',
                            style: TextStyle(
                              color: Color(0xFF6B7F4D),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888)),
        prefixIcon: Icon(icon, color: const Color(0xFF6B7F4D)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6B7F4D), width: 2),
        ),
      );
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6B7F4D).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B7F4D) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6B7F4D) : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF6B7F4D) : Colors.black87,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
