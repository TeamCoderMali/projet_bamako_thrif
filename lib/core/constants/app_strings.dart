/// ─── Bamako Thrift — Chaînes de texte ─────────────────────────────────────
/// Toutes les chaînes statiques de l'application.
/// Pour l'internationalisation future, migrer vers flutter_localizations.
abstract class AppStrings {
  AppStrings._();

  // ── App ────────────────────────────────────────────────────────────────
  static const String appName = 'Bamako Thrift';
  static const String appTagline = 'La mode circulaire au Mali';
  static const String appVersion = '1.0.0';

  // ── Onboarding ─────────────────────────────────────────────────────────
  static const String welcomeTitle = 'Bienvenue sur Bamako Thrift';
  static const String welcomeSubtitle =
      'Achetez et vendez des vêtements de seconde main facilement';
  static const String onboardingTitle1 = 'Découvrez la Mode Durable';
  static const String onboardingSubtitle1 =
      'Des milliers d\'articles de seconde main à petits prix';
  static const String onboardingTitle2 = 'Vendez vos Vêtements';
  static const String onboardingSubtitle2 =
      'Publiez vos articles en quelques secondes';
  static const String onboardingTitle3 = 'Paiement Sécurisé';
  static const String onboardingSubtitle3 =
      'Transactions sécurisées avec Orange Money & Wave';
  static const String getStarted = 'Commencer';
  static const String skip = 'Passer';
  static const String next = 'Suivant';

  // ── Auth ───────────────────────────────────────────────────────────────
  static const String login = 'Se connecter';
  static const String register = 'Créer un compte';
  static const String logout = 'Se déconnecter';
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String resetPassword = 'Réinitialiser le mot de passe';
  static const String email = 'Email';
  static const String password = 'Mot de passe';
  static const String confirmPassword = 'Confirmer le mot de passe';
  static const String fullName = 'Nom complet';
  static const String phoneNumber = 'Numéro de téléphone';
  static const String alreadyHaveAccount = 'Déjà un compte ? ';
  static const String dontHaveAccount = 'Pas encore de compte ? ';
  static const String verifyEmail = 'Vérifiez votre email';
  static const String verifyEmailSubtitle =
      'Un lien de vérification a été envoyé à votre adresse email';
  static const String resendEmail = 'Renvoyer l\'email';
  static const String orContinueWith = 'Ou continuer avec';
  static const String continueWithGoogle = 'Continuer avec Google';
  static const String continueWithPhone = 'Continuer avec téléphone';

  // ── Navigation ─────────────────────────────────────────────────────────
  static const String home = 'Accueil';
  static const String catalog = 'Catalogue';
  static const String publish = 'Publier';
  static const String messages = 'Messages';
  static const String profile = 'Profil';
  static const String search = 'Rechercher';
  static const String filters = 'Filtres';
  static const String notifications = 'Notifications';
  static const String settings = 'Paramètres';
  static const String orders = 'Commandes';
  static const String wallet = 'Portefeuille';

  // ── Products ───────────────────────────────────────────────────────────
  static const String addToCart = 'Ajouter au panier';
  static const String buyNow = 'Acheter maintenant';
  static const String makeOffer = 'Faire une offre';
  static const String contactSeller = 'Contacter le vendeur';
  static const String productDetail = 'Détail du produit';
  static const String similarProducts = 'Articles similaires';
  static const String condition = 'État';
  static const String category = 'Catégorie';
  static const String size = 'Taille';
  static const String brand = 'Marque';
  static const String price = 'Prix';
  static const String description = 'Description';
  static const String publishProduct = 'Publier un article';
  static const String addPhotos = 'Ajouter des photos';
  static const String editProduct = 'Modifier l\'article';
  static const String deleteProduct = 'Supprimer l\'article';

  // ── Payment ────────────────────────────────────────────────────────────
  static const String payment = 'Paiement';
  static const String paymentSuccess = 'Paiement réussi !';
  static const String paymentFailed = 'Paiement échoué';
  static const String totalAmount = 'Montant total';
  static const String choosePaymentMethod = 'Choisir un mode de paiement';
  static const String orangeMoney = 'Orange Money';
  static const String wave = 'Wave';
  static const String card = 'Carte bancaire';

  // ── Orders ─────────────────────────────────────────────────────────────
  static const String trackOrder = 'Suivre ma commande';
  static const String orderHistory = 'Historique des commandes';
  static const String orderStatus = 'Statut de la commande';
  static const String orderConfirmed = 'Commande confirmée';
  static const String orderShipped = 'En livraison';
  static const String orderDelivered = 'Livré';
  static const String orderCancelled = 'Annulé';

  // ── Chat ───────────────────────────────────────────────────────────────
  static const String typeMessage = 'Écrire un message…';
  static const String send = 'Envoyer';
  static const String noMessages = 'Aucun message pour l\'instant';
  static const String startConversation = 'Commencer une conversation';

  // ── Profile ────────────────────────────────────────────────────────────
  static const String editProfile = 'Modifier le profil';
  static const String myListings = 'Mes articles';
  static const String myPurchases = 'Mes achats';
  static const String reviews = 'Avis';
  static const String followers = 'Abonnés';
  static const String following = 'Abonnements';
  static const String follow = 'Suivre';
  static const String unfollow = 'Ne plus suivre';
  static const String reportUser = 'Signaler';

  // ── Admin ──────────────────────────────────────────────────────────────
  static const String adminDashboard = 'Tableau de bord';
  static const String totalUsers = 'Utilisateurs totaux';
  static const String totalProducts = 'Articles totaux';
  static const String totalOrders = 'Commandes totales';
  static const String totalRevenue = 'Revenus totaux';
  static const String pendingReviews = 'En attente de validation';
  static const String bannedUsers = 'Utilisateurs bannis';

  // ── Errors ─────────────────────────────────────────────────────────────
  static const String somethingWentWrong = 'Une erreur est survenue';
  static const String networkError = 'Erreur de connexion';
  static const String noInternetConnection = 'Pas de connexion internet';
  static const String serverError = 'Erreur serveur';
  static const String unauthorizedError = 'Non autorisé';
  static const String notFoundError = 'Introuvable';
  static const String sessionExpired = 'Session expirée, veuillez vous reconnecter';
  static const String tryAgain = 'Réessayer';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String save = 'Enregistrer';
  static const String delete = 'Supprimer';
  static const String edit = 'Modifier';
  static const String close = 'Fermer';
  static const String yes = 'Oui';
  static const String no = 'Non';
  static const String ok = 'OK';
  static const String back = 'Retour';

  // ── Settings ───────────────────────────────────────────────────────────
  static const String darkMode = 'Mode sombre';
  static const String language = 'Langue';
  static const String notifications_ = 'Notifications';
  static const String privacy = 'Confidentialité';
  static const String about = 'À propos';
  static const String termsOfService = 'Conditions d\'utilisation';
  static const String privacyPolicy = 'Politique de confidentialité';
  static const String contactUs = 'Nous contacter';
  static const String rateApp = 'Évaluer l\'app';

  // ── Empty states ───────────────────────────────────────────────────────
  static const String noProductsFound = 'Aucun article trouvé';
  static const String noOrdersYet = 'Aucune commande pour l\'instant';
  static const String noNotificationsYet = 'Aucune notification';
  static const String noFavoritesYet = 'Aucun favori';
  static const String emptyCart = 'Votre panier est vide';

  // ── Validation ─────────────────────────────────────────────────────────
  static const String fieldRequired = 'Ce champ est obligatoire';
  static const String invalidEmail = 'Email invalide';
  static const String passwordTooShort = 'Le mot de passe doit contenir au moins 8 caractères';
  static const String passwordsDoNotMatch = 'Les mots de passe ne correspondent pas';
  static const String invalidPhoneNumber = 'Numéro de téléphone invalide';
  static const String priceMustBePositive = 'Le prix doit être positif';
}
