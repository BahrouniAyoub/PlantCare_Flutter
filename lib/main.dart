import 'package:flutter/material.dart';
import 'package:flutter_onboarding/ui/screens/ChatWithLLMScreen%20.dart';
import 'package:flutter_onboarding/ui/screens/signin_page.dart';
import 'ui/onboarding_screen.dart';
// import 'ui/screens/signin_page.dart';




void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
