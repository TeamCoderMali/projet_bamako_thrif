/// ─── Bamako Thrift — Regex de validation ──────────────────────────────────
abstract class AppRegex {
  AppRegex._();

  static final RegExp email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp password = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
  );

  static final RegExp passwordSimple = RegExp(r'^.{8,}$');

  /// Numéros maliens : +223 XX XX XX XX ou 00223...
  static final RegExp malianPhone = RegExp(
    r'^(\+223|00223)?[567]\d{7}$',
  );

  static final RegExp internationalPhone = RegExp(
    r'^\+?[1-9]\d{7,14}$',
  );

  static final RegExp url = RegExp(
    r'^(https?|ftp):\/\/[^\s/$.?#].[^\s]*$',
  );

  static final RegExp alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');

  static final RegExp numeric = RegExp(r'^\d+$');

  static final RegExp decimalPrice = RegExp(r'^\d+(\.\d{1,2})?$');

  static final RegExp postalCode = RegExp(r'^\d{5}$');

  static final RegExp username = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  static final RegExp noSpecialChars = RegExp(r'^[a-zA-Z\s]+$');
}
