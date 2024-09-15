import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:outreachapp/screens/loginpage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

Future<void> storeUserProfile(String firstName, String lastName, bool isAdmin,
    List<String> events, String email) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .set({
      'first_name': firstName,
      'last_name': lastName,
      'isAdmin': isAdmin,
      'events': events,
      'id': 'placeholder',
      'email': email,
    });
    debugPrint('User profile stored successfully.');
  } on FirebaseException catch (e) {
    debugPrint('Failed to store user profile: ${e.message}');
  }
}

Future<void> createUserAccount(String email, String password) async {
  try {
    final UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    debugPrint('User account created for ${userCredential.user!.email}.');
  } on FirebaseAuthException catch (e) {
    debugPrint('Failed to create user: ${e.message}');
  }
}

Future<void> registerNewUser(String email, String password, String firstName,
    String lastName, bool role) async {
  await createUserAccount(email, password);

  List<String> events = [];
  await storeUserProfile(firstName, lastName, role, events, email);
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController userEmail = TextEditingController();
  TextEditingController userPassword = TextEditingController();
  TextEditingController userFirstName = TextEditingController();
  TextEditingController userLastName = TextEditingController();
  TextEditingController userAdminPassword = TextEditingController();
  List<DropdownMenuEntry> userOptions = List.empty(growable: true);
  DropdownMenuEntry adminOption =
      const DropdownMenuEntry(value: "admin", label: "Admin");
  DropdownMenuEntry memberOption =
      const DropdownMenuEntry(value: "member", label: "General Member");
  String? chosenOption;

  @override
  void initState() {
    super.initState();
    userOptions.add(adminOption);
    userOptions.add(memberOption);
  }

  @override
  Widget build(BuildContext context) {
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
                    "Register",
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 20,
                  ),
                  const Text("First Name"),
                  const SizedBox(
                    width: double.infinity,
                    height: 8,
                  ),
                  TextFormField(
                    controller: userFirstName,
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 20,
                  ),
                  const Text("Last Name"),
                  TextFormField(
                    controller: userLastName,
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 20,
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 8,
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
                  DropdownMenu(
                    dropdownMenuEntries: userOptions,
                    onSelected: (value) {
                      setState(() {
                        chosenOption = value.toString();
                        debugPrint('Chosen option updated: $chosenOption');
                      });
                    },
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 20,
                  ),
                  const Text("For Admin Users ONLY: Admin Password"),
                  TextFormField(
                    controller: userAdminPassword,
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 20,
                  ),
                  TextButton(
                    onPressed: () async {
                      String firstName = userFirstName.text;
                      String lastName = userLastName.text;
                      String enteredAdminPassword =
                          userAdminPassword.text.trim();
                      bool role = false;

                      debugPrint(
                          "Entered Admin Password: $enteredAdminPassword");
                      debugPrint("Chosen Option: $chosenOption");

                      if ((chosenOption == "admin") &&
                          (enteredAdminPassword == "iaoutreach")) {
                        role = true;
                        debugPrint("Admin password matched.");
                      } else {
                        debugPrint("Admin password not matched.");
                      }

                      String email = userEmail.text;
                      String password = userPassword.text;

                      debugPrint("Registering as $chosenOption");

                      await registerNewUser(
                          email, password, firstName, lastName, role);

                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.green),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                    ),
                    child: const Text("Register"),
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 20,
                  ),
                  GestureDetector(
                    child: const Text(
                      "Already have an account? Log in here!",
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
