import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:grocermate/firebase_options.dart';
import 'package:grocermate/screens/login_screen.dart';
import 'package:grocermate/screens/main_navigation.dart';
import 'package:grocermate/services/notification_service.dart';
import 'package:grocermate/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  StreamSubscription? _authSubscription;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      setState(() {}); // Força rebuild para atualizar a rota
      if (session != null) {
        // User is logged in, initialize notifications
        _notificationService.initNotifications();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    return MaterialApp(
      title: 'GrocerMate',
      theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      // Se houver uma sessão ativa, a rota inicial é a navegação principal, senão, é o login.
      initialRoute: session == null ? '/login' : '/',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/': (context) => MainNavigation(onThemeToggle: _toggleTheme),
      },
    );
  }
}
