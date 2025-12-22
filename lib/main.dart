import 'package:alignme/pages/splash_page.dart';
import 'package:alignme/theme_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ NEW
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'AlignMe',
        body: message.notification!.body ?? '',
      );
    }
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AlignMeApp(),
    ),
  );
}

Future<void> _showLocalNotification({
  required String title,
  required String body,
}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'alignme_channel',
    'AlignMe Notifications',
    channelDescription: 'Posture and health notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    playSound: true,
    visibility: NotificationVisibility.public,
    fullScreenIntent: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecond,
    title,
    body,
    notificationDetails,
  );
}

class AlignMeApp extends StatelessWidget {
  const AlignMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // 🌞 Light Theme Base
    final lightBase = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FBFF),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5B9C9C),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FBFF),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      useMaterial3: true,
    );

    // 🌙 Dark Theme Base
    final darkBase = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5B9C9C),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
      ),
      useMaterial3: true,
    );

    // ✅ Apply Cairo font to whole app
    final lightTheme = lightBase.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(lightBase.textTheme),
    );

    final darkTheme = darkBase.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(darkBase.textTheme),
    );

    return MaterialApp(
      title: 'AlignMe',
      debugShowCheckedModeBanner: false,

      // ✅ ThemeProvider
      themeMode: themeProvider.themeMode,

      theme: lightTheme,
      darkTheme: darkTheme,

      home: const SplashScreen(),
    );
  }
}
