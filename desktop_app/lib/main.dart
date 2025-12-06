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
        Provider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: MaterialApp(
        title: 'SafeCopy Owner Client',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const LoginScreen(),
      ),
    );
  }
}
