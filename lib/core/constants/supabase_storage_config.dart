// ─── Bamako Thrift — Config Supabase Storage ───────────────────────────────
// Remplace Firebase Storage (bucket jamais provisionné, projet resté sur le
// forfait Spark — voir l'audit du 2026-10-15). Clé "publishable" : faite
// pour être embarquée côté client (pas un secret), restreinte en écriture
// par une policy SQL côté Supabase (INSERT seul, bucket danaya, préfixes
// product_images/ et avatars/ — pas de UPDATE/DELETE/LIST pour ce rôle).
abstract class SupabaseStorageConfig {
  SupabaseStorageConfig._();

  static const String projectUrl = 'https://yyxmrojimpapyaukdjue.supabase.co';
  static const String publishableKey =
      'sb_publishable_zpTjhnUmXjqtZhmb_8wtoA_b8zUJIfq';
  static const String bucket = 'danaya';
}
