// ─── Bamako Thrift — Theme Cubit ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = 'theme_mode';
  // Ancienne clé booléenne (avant le mode "automatique") — migrée puis
  // supprimée au premier lancement suivant cette mise à jour.
  static const _legacyKey = 'dark_mode';

  // Défaut = clair (pas "system") : l'appli ne doit pas démarrer en mode
  // sombre selon le thème de l'appareil tant que l'utilisateur n'a rien
  // choisi explicitement. Un choix stocké (y compris "system" choisi à la
  // main) prime toujours sur ce défaut, voir _load().
  ThemeCubit() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);

    if (stored == null) {
      // Migration : un choix explicite clair/sombre existant prime sur le
      // nouveau défaut "automatique".
      final legacyIsDark = prefs.getBool(_legacyKey);
      if (legacyIsDark != null) {
        final mode = legacyIsDark ? ThemeMode.dark : ThemeMode.light;
        await prefs.remove(_legacyKey);
        await prefs.setString(_key, _encode(mode));
        emit(mode);
        return;
      }
      emit(ThemeMode.light);
      return;
    }

    emit(_decode(stored));
  }

  Future<void> setMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _encode(mode));
    emit(mode);
  }

  bool get isDark => state == ThemeMode.dark;

  String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  ThemeMode _decode(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
