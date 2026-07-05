# Bamako Thrift 🛍️

> La marketplace de vêtements de seconde main au Mali

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase)](https://firebase.google.com)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-green)](https://blog.cleancoder.com)

---

## 📐 Architecture

Ce projet suit une **Clean Architecture** stricte avec séparation en 3 couches :

```
lib/
├── core/                         # Noyau partagé par toutes les features
│   ├── constants/                # Couleurs, tailles, strings, regex...
│   ├── theme/                    # Light & Dark theme (Material 3)
│   ├── router/                   # GoRouter — navigation centralisée
│   ├── network/                  # Dio + Firebase clients
│   ├── exceptions/               # Failures & Exceptions
│   ├── storage/                  # LocalStorage + SecureStorage
│   ├── services/                 # Snackbar, Dialog, Navigation...
│   ├── utils/                    # Validators, Formatter, Helpers
│   ├── extensions/               # Extensions Dart (String, Date, Widget...)
│   └── dependency_injection/     # GetIt + Injectable
│
├── features/                     # 13 features indépendantes
│   ├── onboarding/
│   ├── auth/
│   ├── home/
│   ├── catalog/
│   ├── product/
│   ├── publish/
│   ├── payment/
│   ├── order/
│   ├── chat/
│   ├── profile/
│   ├── notification/
│   ├── settings/
│   └── admin/
│
└── shared/
    └── widgets/                  # Widgets réutilisables cross-feature
```

Chaque feature suit la structure **Data / Domain / Presentation** :

```
feature/
├── data/
│   ├── datasources/              # Firebase / API data sources
│   ├── models/                   # Modèles avec sérialisation JSON
│   └── repositories/             # Implémentation des repositories
├── domain/
│   ├── entities/                 # Entités pures (sans framework)
│   ├── repositories/             # Contrats abstraits
│   └── usecases/                 # Logique métier isolée
└── presentation/
    ├── pages/                    # Écrans
    ├── widgets/                  # Widgets spécifiques à la feature
    ├── cubit/                    # Cubits (flutter_bloc)
    ├── bloc/                     # États BLoC
    ├── controllers/              # Logique de contrôle (formulaires...)
    ├── providers/                # Providers locaux
    └── bindings/                 # Configuration des dépendances
```

---

## 🛠️ Stack Technique

| Couche | Technologie |
|--------|-------------|
| **UI** | Flutter 3 + Material 3 |
| **State** | flutter_bloc + Cubit |
| **Navigation** | GoRouter |
| **DI** | get_it + injectable |
| **Network** | Dio |
| **Backend** | Firebase (Auth, Firestore, Storage, FCM) |
| **Cache** | cached_network_image |
| **Storage** | shared_preferences + flutter_secure_storage |
| **Responsive** | flutter_screenutil |
| **Codegen** | freezed + json_serializable |

---

## 🚀 Démarrage

### Prérequis
- Flutter SDK ≥ 3.6.2
- Dart SDK ≥ 3.0
- Firebase project configuré

### Installation

```bash
# 1. Cloner le projet
git clone <repo-url>
cd bamako_thrift

# 2. Installer les dépendances
flutter pub get

# 3. Configurer Firebase
flutterfire configure

# 4. Générer le code (freezed, injectable...)
flutter pub run build_runner build --delete-conflicting-outputs

# 5. Lancer l'application
flutter run
```

---

## 📁 Fichiers importants

| Fichier | Rôle |
|---------|------|
| `lib/main.dart` | Point d'entrée, initialisation |
| `lib/core/router/app_router.dart` | Configuration GoRouter |
| `lib/core/theme/light_theme.dart` | Thème Material 3 clair |
| `lib/core/theme/dark_theme.dart` | Thème Material 3 sombre |
| `lib/core/dependency_injection/injection.dart` | Setup GetIt |
| `lib/core/constants/app_colors.dart` | Palette de couleurs |

---

## 🎨 Design System

- **Couleur primaire** : `#1A7A5E` (Vert forêt)
- **Couleur secondaire** : `#F4A261` (Ocre chaud)
- **Typographie** : Inter
- **Grille** : 4px base
- **Thèmes** : Light & Dark (Material 3)

---

## 🔥 Firebase Collections

| Collection | Description |
|------------|-------------|
| `users` | Profils utilisateurs |
| `products` | Articles en vente |
| `orders` | Commandes |
| `chats` | Conversations |
| `notifications` | Notifications push |
| `reviews` | Avis et évaluations |
| `categories` | Catégories de produits |

---

## ⚡ Commandes utiles

```bash
# Analyser le code
flutter analyze

# Lancer les tests
flutter test

# Générer le code (freezed, json_serializable, injectable)
flutter pub run build_runner build --delete-conflicting-outputs

# Watcher (génération continue)
flutter pub run build_runner watch --delete-conflicting-outputs

# Build APK release
flutter build apk --release

# Build iOS release
flutter build ios --release
```

---

## 📝 Conventions de nommage

- **Fichiers** : `snake_case.dart`
- **Classes** : `PascalCase`
- **Variables/méthodes** : `camelCase`
- **Constantes** : `SCREAMING_SNAKE_CASE` ou `camelCase` dans les classes `abstract`
- **Branches Git** : `feature/nom-feature`, `fix/description-bug`, `chore/description`

---

*Développé avec ❤️ pour Bamako Thrift*
