import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/encryption_service.dart';
import 'services/key_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'screens/login_screen.dart';

// Global key for navigation without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize();
  });

  // Initialize redirection on auth failure
  ApiService.onUnauthorized = () {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  };

  runApp(const SafeCopyDesktopApp());
}

class SafeCopyDesktopApp extends StatelessWidget {
  const SafeCopyDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => ApiService()),
        Provider(create: (_) => EncryptionService()),
        Provider(create: (_) => KeyService()),
        Provider(
          create: (_) => NotificationService(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: MaterialApp(
        title: 'SafeCopy Owner Client',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        themeMode: ThemeMode.system,
        navigatorKey: navigatorKey, // Set the global navigator key
        home: const LoginScreen(),
        routes: {'/login': (context) => const LoginScreen()},
      ),
    );
  }
}
