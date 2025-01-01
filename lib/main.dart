import 'package:demo/firebase_options.dart';
import 'package:demo/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'signup.dart'; // Import the SignupPage widget
import 'rnn_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login & Registration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      // Define named routes
      routes: {
        '/': (context) => const LoginPage(),
        '/signup': (context) => const RegistrationPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
         '/rnn': (context) => const RnnPage(),
      },
      // Set the initial route
      initialRoute: '/',
    );
  }
}
