import 'package:firebase_core/firebase_core.dart';
import 'package:outreachapp/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:outreachapp/screens/loginpage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("Widgets initialized!");
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Firebase initialized!");
  runApp(const OutreachApp());
}

class OutreachApp extends StatefulWidget {
  const OutreachApp({super.key});

  @override
  State<OutreachApp> createState() => _OutreachAppState();
}

class _OutreachAppState extends State<OutreachApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Outreach",
      theme: ThemeData(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: "Poppins",
            ),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          indicatorColor: Colors.deepPurple,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              color: Colors.white,
              fontFamily: "Poppins",
            ),
          ),
        ),
        dialogBackgroundColor: const Color.fromRGBO(32, 37, 70, 1),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurple,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        useMaterial3: true,
        dialogTheme: DialogTheme(
          surfaceTintColor: Colors.transparent,
          elevation: 20,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color.fromRGBO(32, 37, 70, 1),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: "Poppins",
          ),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontFamily: "Poppins",
          ),
        ),
        brightness: Brightness.dark,
        fontFamily: "Poppins",
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(32, 37, 70, 1),
        ),
        timePickerTheme: TimePickerThemeData(
          dialTextStyle: const TextStyle(
            color: Colors.white,
            fontFamily: "Poppins",
            fontSize: 20,
          ),
          helpTextStyle: const TextStyle(
            color: Colors.white,
            fontFamily: "Poppins",
          ),
          dayPeriodTextStyle: const TextStyle(
            color: Colors.white,
            fontFamily: "Poppins",
            fontSize: 18,
          ),
          hourMinuteTextStyle: const TextStyle(
            color: Colors.white,
            fontFamily: "Poppins",
            fontSize: 44,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.red.shade900,
          dialHandColor: Colors.redAccent,
          dialTextColor: Colors.white,
          dayPeriodTextColor: Colors.white,
          hourMinuteTextColor: Colors.white,
          entryModeIconColor: Colors.transparent,
          hourMinuteColor: Colors.red,
          cancelButtonStyle: const ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            backgroundColor: WidgetStatePropertyAll(Colors.redAccent),
            overlayColor: WidgetStatePropertyAll(Colors.redAccent),
          ),
          confirmButtonStyle: const ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            backgroundColor: WidgetStatePropertyAll(Colors.redAccent),
            overlayColor: WidgetStatePropertyAll(Colors.redAccent),
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          headerBackgroundColor: Colors.red,
          backgroundColor: Colors.red.shade900,
        ),
        colorScheme: const ColorScheme(
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.black,
          onSurface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          primary: Colors.blueGrey,
          secondary: Color.fromARGB(255, 70, 70, 70),
          brightness: Brightness.dark,
        ),
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
