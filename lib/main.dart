import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'adminscreen.dart';
import 'login.dart';
import 'mark.dart';
import 'markupload.dart';
import 'createteacher.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ----------- FIREBASE INITIALIZATION ------------
  try {
    if (Platform.isWindows) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBvRSsbxN8ik1e9RtmpHQIqFXmjYhtpFiE",
          authDomain: "scoe-322c3.firebaseapp.com",
          projectId: "scoe-322c3",
          storageBucket: "scoe-322c3.appspot.com",
          messagingSenderId: "772152576969",
          appId: "1:772152576969:web:5dc7b951c756a6df927618",
          measurementId: "G-XV2R87NXY0",
        ),
      );
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print("Firebase Init Error: $e");
  }

  // ----------- GLOBAL ERROR HANDLER ------------
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    print("Caught error: $error");
    print(stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'College App',
      theme: ThemeData(useMaterial3: true),

      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/markupload': (context) => const UploadMarksScreen(),
        '/marklist': (context) => const MarkListScreen(),
        '/createteacher': (context) => const Createteacher(),
      },
    );
  }
}
