import 'package:flutter/material.dart';
import 'package:flutter_onboarding/ui/screens/ChatWithLLMScreen%20.dart';
import 'package:flutter_onboarding/ui/screens/signin_page.dart';
import 'ui/onboarding_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_onboarding/ui/screens/assign_plant_page.dart';

// import 'ui/screens/signin_page.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();





void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize time zone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Berlin')); // Or your local timezone

  // Initialize notifications
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(initSettings);

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantCare',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SignIn(),
        '/signin_page': (context) => const SignIn(),
        '/chat': (context) => const ChatWithLLMScreen(),

      },
    );
  }
}
