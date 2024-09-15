// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:outreachapp/screens/alleventspage.dart';
import 'package:outreachapp/screens/allscreenscontainer.dart';

class PostEditor extends StatefulWidget {
  const PostEditor({
    super.key,
    required this.postBody,
    required this.postTitle,
    required this.id,
    required this.posted,
    required this.poster,
  });

  final String postTitle;
  final String postBody;
  final String id;
  final DateTime? posted;
  final String poster;

  @override
  State<PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor> {
  @override
  Widget build(BuildContext context) {
    TextEditingController editedPostTitle = TextEditingController(
      text: widget.postTitle,
    );
    TextEditingController editedPostBody = TextEditingController(
      text: widget.postBody,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Edit Post"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        backgroundColor: Colors.black,
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AllEventsPage()),
            );
          },
        ),
      ),
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
                  TextFormField(
                    controller: editedPostTitle,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 8,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(
                      left: 18.0,
                      right: 18.0,
                    ),
                  ),
                  TextFormField(
                    controller: editedPostBody,
                  ),
                  const SizedBox(
                    width: double.infinity,
                    height: 8,
                  ),
                  TextButton(
                    onPressed: () async {
                      String name = editedPostTitle.text;
                      String info = editedPostBody.text;

                      Map<String, dynamic> eventMap = {
                        'title': name.toString(),
                        'body': info.toString(),
                        'poster': widget.poster.toString(),
                        'id': widget.id.toString(),
                        'posted': widget.posted!.toIso8601String(),
                      };

                      try {
                        // Update the document in Firestore
                        await FirebaseFirestore.instance
                            .collection('posts')
                            .doc(widget.id)
                            .set(eventMap);

                        // Navigate back to the previous screen
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const AllScreensContainer(),
                          ),
                        );
                      } catch (e) {
                        debugPrint("Error caught: $e");
                      }

                      // Optionally, show a success message
                    },
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.green),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                    ),
                    child: const Text("Confirm Edits"),
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
