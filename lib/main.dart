import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Initialize notifications in the background so it doesn't block startup
    NotificationService().init();
    
    runApp(const CadenceApp());
  } catch (e) {
    debugPrint('Startup sequence error: $e');
    runApp(const CadenceApp());
  }
}

class CadenceApp extends StatefulWidget {
  const CadenceApp({super.key});

  static CadenceAppState of(BuildContext context) =>
      context.findAncestorStateOfType<CadenceAppState>()!;

  @override
  State<CadenceApp> createState() => CadenceAppState();
}

class CadenceAppState extends State<CadenceApp> {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final uid = AuthService().currentUser?.uid ?? 'guest';
    final mode = await StorageService(uid).loadThemeMode();
    setState(() {
      _themeMode = mode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setState(() {
      _themeMode = newMode;
    });
    final uid = AuthService().currentUser?.uid ?? 'guest';
    await StorageService(uid).saveThemeMode(newMode == ThemeMode.dark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadence',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(isDark: false),
      darkTheme: buildAppTheme(isDark: true),
      themeMode: _themeMode,
      home: const SplashScreen(),
    );
  }
}
