import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Añadido para detectar el modo Debug (kDebugMode)
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Descomentado para bloquear bots y hackeos
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'models/maintenance_model.dart';
import 'models/vehicle_model.dart';
import 'providers/vehicle_provider.dart';
import 'providers/maintenance_provider.dart';
import 'models/fuel_model.dart';
import 'providers/fuel_provider.dart';
import 'models/document_model.dart';
import 'providers/document_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/revenuecat_service.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';
import 'auth/login_screen.dart';

void main() async {
  // 1. Inicializar Flutter (Requisito fundamental)
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // --- CACHEO DE DATOS EN LA NUBE ---
    // Activamos la persistencia offline de Firestore. Permite navegar, leer 
    // y escribir datos sin consumir internet (Rate Limiting en base de datos)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Cachea todo lo posible en el móvil
    );

    // --- PROTECCIÓN ANTI-BOTS Y ANTI-MODS (APP CHECK) ---
    // Usamos Play Integrity en producción para evitar que modifiquen tu APK,
    // pero permitimos tokens de Debug cuando estás programando en tu PC para no bloquearte.
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
    // ----------------------------------------------------

    // --- 3. CONFIGURACIÓN DE ESTABILIDAD: Crashlytics ---
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    // ----------------------------------------------------

    // 4. Inicializar Hive (Bases de datos locales)
    await Hive.initFlutter();

    // 5. Registrar los Adaptadores de Hive
    Hive.registerAdapter(VehicleAdapter());
    Hive.registerAdapter(MaintenanceAdapter());
    Hive.registerAdapter(FuelLogAdapter());
    Hive.registerAdapter(VehicleDocumentAdapter());

    // 6. Abrir las cajas de forma segura (borra y recrea si hay conflicto de modelo)
    await _openBoxSafely<Vehicle>('vehicles_box');
    await _openBoxSafely<Maintenance>('maintenances_box');
    await _openBoxSafely<FuelLog>('fuel_box');
    await _openBoxSafely<VehicleDocument>('documents_box');

    // --- 7. INICIALIZAR MOTOR DE NOTIFICACIONES LOCALES ---
    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint("Error inicializando notificaciones: $e");
    }
    // ---------------------------------------------
    
    // --- 8. INICIALIZAR REVENUECAT Y ADMOB ---
    await RevenueCatService.init();
    await AdService.instance.init();

    // Escuchar cambios de Auth para vincular suscripción de RevenueCat con la cuenta de Firebase
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        RevenueCatService.login(user.uid);
      } else {
        RevenueCatService.logout();
      }
    });
    // ---------------------------------------------
  } catch (e, stack) {
    debugPrint("Error fatal en el inicio (Splash screen): $e\n$stack");
    // Fallback UI si falla la inicialización total
    runApp(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 60.0, left: 16.0, right: 16.0),
            child: Center(
              child: Text(
                "Error al cargar la app:\n\n$e\n\nDetalles:\n$stack",
                textAlign: TextAlign.left,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    ));
    return;
  }

  runApp(
    // 9. Inyectar los Providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleProvider()..loadVehicles()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()..loadMaintenances()),
        ChangeNotifierProvider(create: (_) => FuelProvider()..loadFuelLogs()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()..loadDocuments()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: const VehicleTrackerApp(),
    ),
  );
}

// Función auxiliar para abrir cajas de Hive previniendo cuelgues en la Splash Screen
Future<void> _openBoxSafely<T>(String boxName) async {
  try {
    await Hive.openBox<T>(boxName);
  } catch (e) {
    debugPrint("Error abriendo caja \$boxName: \$e. Borrando y recreando...");
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox<T>(boxName);
  }
}

class VehicleTrackerApp extends StatefulWidget {
  const VehicleTrackerApp({super.key});

  @override
  State<VehicleTrackerApp> createState() => _VehicleTrackerAppState();
}

class _VehicleTrackerAppState extends State<VehicleTrackerApp> {
  // Instancias globales para Analytics
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);
  late AppLifecycleReactor _appLifecycleReactor;

  @override
  void initState() {
    super.initState();
    _appLifecycleReactor = AppLifecycleReactor(
      adService: AdService.instance,
      isPremiumCheck: () => Provider.of<SubscriptionProvider>(context, listen: false).isPremium,
    );
    WidgetsBinding.instance.addObserver(_appLifecycleReactor);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_appLifecycleReactor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Vehio',
          debugShowCheckedModeBanner: false,
          navigatorObservers: <NavigatorObserver>[observer],
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFFE50914),
            scaffoldBackgroundColor: const Color(0xFFF4F5F7),
            cardColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE50914),
              secondary: Color(0xFF1E232B),
              surface: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFE50914),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E232B),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE50914),
              secondary: Color(0xFFF4F5F7),
              surface: Color(0xFF1E232B),
            ),
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}