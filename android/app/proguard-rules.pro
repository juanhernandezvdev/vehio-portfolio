# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Play Store Split / Deferred Components
-dontwarn com.google.android.play.core.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Unity Ads
-keepattributes SourceFile,LineNumberTable
-keepattributes JavascriptInterface
-keep class com.unity3d.ads.** {*;}
-keep class com.unity3d.services.** {*;}
-dontwarn com.unity3d.services.**
-dontwarn com.unity3d.ads.**

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }
-keep interface com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.crashlytics.** { *; }
-dontwarn com.crashlytics.**