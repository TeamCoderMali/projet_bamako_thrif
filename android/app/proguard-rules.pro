# Filet de sécurité -- Firebase, Google Sign-In et Play Integrity embarquent
# déjà leurs propres règles consumer-proguard dans leurs AAR (appliquées
# automatiquement par R8). Ces quelques règles évitent une régression si une
# dépendance future n'en fournit pas.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.play.core.integrity.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
