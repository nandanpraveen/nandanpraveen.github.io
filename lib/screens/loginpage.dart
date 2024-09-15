// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:outreachapp/presetobjects.dart';
import 'package:outreachapp/screens/allscreenscontainer.dart';
import 'package:outreachapp/screens/registerpage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

Future<Map<String, dynamic>?> getUserProfile() async {
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    if (!userDoc.exists || userDoc.data() == null) {
      debugPrint('No user found with the provided UID.');
      return null;
    }

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    currentUser = LocalUser(
      firstName: userData['first_name'] ?? '',
      lastName: userData['last_name'] ?? '',
      email: userData['email'] ?? '',
      password: userData['password'] ??
          '', // Note: Storing passwords in Firestore is not recommended for security reasons
      isAdmin: userData['isAdmin'] ?? false,
      events: List<String>.from(userData['events'] ?? []),
    );

    return userData;
  } on FirebaseException catch (e) {
    debugPrint('Failed to get user profile: ${e.message}');
    rethrow;
  }
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    Future<void> signInWithEmailPassword(String email, String password) async {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        debugPrint('User signed in successfully.');

        await getUserProfile();
        debugPrint("Information about the current user:");
        debugPrint(currentUser.firstName);
        debugPrint(currentUser.lastName);
        debugPrint(currentUser.email);
        debugPrint(currentUser.isAdmin.toString());
        debugPrint(currentUser.events.toString());

        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AllScreensContainer()),
        );
      } on FirebaseAuthException catch (e) {
        debugPrint('Failed to sign in: ${e.message}');
        // Show an error message to the user
      }
    }

    TextEditingController userEmail = TextEditingController();
    TextEditingController userPassword = TextEditingController();
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 32),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    "Login",
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 20,
                  ),
                  const Text("Email"),
                  TextFormField(
                    controller: userEmail,
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 8,
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 20,
                  ),
                  const Text("Password"),
                  TextFormField(
                    controller: userPassword,
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 20,
                  ),
                  TextButton(
                    onPressed: () {
                      String loginEmail = userEmail.text;
                      String loginPassword = userPassword.text;
                      setState(() {});
                      signInWithEmailPassword(loginEmail, loginPassword)
                          .then((_) {
                        getUserProfile();
                      });
                      debugPrint("Information about the current user:");
                      debugPrint(currentUser.firstName);
                      debugPrint(currentUser.lastName);
                      debugPrint(currentUser.email);
                      debugPrint(currentUser.password);
                      debugPrint(currentUser.events.toString());
                      debugPrint(currentUser.isAdmin.toString());
                    },
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.green),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                    ),
                    child: const Text("Login"),
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 20,
                  ),
                  GestureDetector(
                    child: const Text(
                      "Need an account? Make one here!",
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const RegisterPage()),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
