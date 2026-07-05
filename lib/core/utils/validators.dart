/// ─── Bamako Thrift — Validators ────────────────────────────────────────────
import '../constants/app_regex.dart';
import '../constants/app_strings.dart';

/// Classe utilitaire de validation de formulaires.
/// Compatible avec TextFormField.validator.
abstract class Validators {
  Validators._();

  // ── Email ──────────────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (!AppRegex.email.hasMatch(value.trim())) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  // ── Password ───────────────────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (!AppRegex.passwordSimple.hasMatch(value)) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) return AppStrings.fieldRequired;
      if (value != password) return AppStrings.passwordsDoNotMatch;
      return null;
    };
  }

  // ── Phone ──────────────────────────────────────────────────────────────
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (!AppRegex.malianPhone.hasMatch(value.trim()) &&
        !AppRegex.internationalPhone.hasMatch(value.trim())) {
      return AppStrings.invalidPhoneNumber;
    }
    return null;
  }

  // ── Required ───────────────────────────────────────────────────────────
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    return null;
  }

  // ── Price ──────────────────────────────────────────────────────────────
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return AppStrings.priceMustBePositive;
    return null;
  }

  // ── Min/Max length ─────────────────────────────────────────────────────
  static String? Function(String?) minLength(int min, [String? message]) {
    return (String? value) {
      if (value == null || value.isEmpty) return AppStrings.fieldRequired;
      if (value.length < min) {
        return message ?? 'Minimum $min caractères requis';
      }
      return null;
    };
  }

  static String? Function(String?) maxLength(int max, [String? message]) {
    return (String? value) {
      if (value != null && value.length > max) {
        return message ?? 'Maximum $max caractères autorisés';
      }
      return null;
    };
  }

  // ── URL ────────────────────────────────────────────────────────────────
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optionnel
    if (!AppRegex.url.hasMatch(value.trim())) return 'URL invalide';
    return null;
  }

  // ── Combiner plusieurs validateurs ─────────────────────────────────────
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
