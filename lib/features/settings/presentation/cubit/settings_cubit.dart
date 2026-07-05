// ─── Bamako Thrift — Settings Cubit & State ────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/local_storage.dart';

// ── Keys ───────────────────────────────────────────────────────────────────
const String _kThemeMode = 'settings_theme_mode';
const String _kLanguage = 'settings_language';
const String _kNotifPush = 'settings_notif_push';
const String _kNotifMessages = 'settings_notif_messages';
const String _kNotifOrders = 'settings_notif_orders';

// ── State ──────────────────────────────────────────────────────────────────
class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final String language;
  final bool pushNotificationsEnabled;
  final bool messageNotificationsEnabled;
  final bool orderNotificationsEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.language = 'fr',
    this.pushNotificationsEnabled = true,
    this.messageNotificationsEnabled = true,
    this.orderNotificationsEnabled = true,
  });

  @override
  List<Object?> get props => [
        themeMode, language, pushNotificationsEnabled,
        messageNotificationsEnabled, orderNotificationsEnabled,
      ];

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? pushNotificationsEnabled,
    bool? messageNotificationsEnabled,
    bool? orderNotificationsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      messageNotificationsEnabled:
          messageNotificationsEnabled ?? this.messageNotificationsEnabled,
      orderNotificationsEnabled:
          orderNotificationsEnabled ?? this.orderNotificationsEnabled,
    );
  }
}

// ── Cubit ──────────────────────────────────────────────────────────────────
class SettingsCubit extends Cubit<SettingsState> {
  final LocalStorage _storage;

  SettingsCubit({required LocalStorage storage})
      : _storage = storage,
        super(const SettingsState());

  Future<void> loadSettings() async {
    final themeIndex = _storage.getInt(_kThemeMode) ?? 0;
    final language = _storage.getString(_kLanguage) ?? 'fr';
    final pushNotif = _storage.getBool(_kNotifPush) ?? true;
    final msgNotif = _storage.getBool(_kNotifMessages) ?? true;
    final orderNotif = _storage.getBool(_kNotifOrders) ?? true;

    emit(SettingsState(
      themeMode: ThemeMode.values[themeIndex],
      language: language,
      pushNotificationsEnabled: pushNotif,
      messageNotificationsEnabled: msgNotif,
      orderNotificationsEnabled: orderNotif,
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _storage.setInt(_kThemeMode, mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setLanguage(String lang) async {
    await _storage.setString(_kLanguage, lang);
    emit(state.copyWith(language: lang));
  }

  Future<void> togglePushNotifications() async {
    final newVal = !state.pushNotificationsEnabled;
    await _storage.setBool(_kNotifPush, value: newVal);
    emit(state.copyWith(pushNotificationsEnabled: newVal));
  }

  Future<void> toggleMessageNotifications() async {
    final newVal = !state.messageNotificationsEnabled;
    await _storage.setBool(_kNotifMessages, value: newVal);
    emit(state.copyWith(messageNotificationsEnabled: newVal));
  }

  Future<void> toggleOrderNotifications() async {
    final newVal = !state.orderNotificationsEnabled;
    await _storage.setBool(_kNotifOrders, value: newVal);
    emit(state.copyWith(orderNotificationsEnabled: newVal));
  }
}
