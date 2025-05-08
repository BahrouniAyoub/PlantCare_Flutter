import 'package:flutter/material.dart';
import 'package:flutter_onboarding/ui/screens/signin_page.dart';
import 'ui/onboarding_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'ui/screens/signin_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initNotifications();
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
        '/': (context) => const OnboardingScreen(),
        '/signin_page': (context) => const SignIn(),
      },
    );
  }
}
