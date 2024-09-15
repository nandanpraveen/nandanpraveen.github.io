import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:outreachapp/presetobjects.dart';
import 'package:outreachapp/screens/editpost.dart';

class PostViewPage extends StatefulWidget {
  const PostViewPage({super.key});

  @override
  State<PostViewPage> createState() => _PostViewPageState();
}

class PostCard extends StatelessWidget {
  final Post post;

  // ignore: use_key_in_widget_constructors
  const PostCard({required this.post});

  Future<void> deletePost(String postId) async {
    if (currentUser.isAdmin) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple,
      margin: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: double.infinity - 20,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          if (currentUser.isAdmin) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PostEditor(
                                  postBody: post.body,
                                  postTitle: post.title,
                                  posted: post.posted,
                                  poster: post.poster,
                                  id: post.id,
                                ),
                              ),
                            );
                          } else {}
                          // ignore: use_build_context_synchronously
                        },
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () async {
                          await deletePost(post.id);
                          // ignore: use_build_context_synchronously
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [const Icon(Icons.person), Text(post.poster)],
              ),
              const SizedBox(height: 8.0),
              Text(
                "Posted at ${post.posted.hour}:${timeFixer(post.posted.minute)} on ${post.posted.month}/${post.posted.day}/${post.posted.year}",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8.0),
              Text(post.body),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostViewPageState extends State<PostViewPage> {
  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot<Map<String, dynamic>>> postsStream =
        FirebaseFirestore.instance.collection('posts').snapshots();
    Color userChosenAccent = Colors.deepPurple;

    return Scaffold(
      floatingActionButton: currentUser.isAdmin
          ? FloatingActionButton(
              foregroundColor: Colors.white,
              onPressed: () async {
                Post newPost = Post();
                TextEditingController postNameController =
                    TextEditingController();
                TextEditingController postBodyController =
                    TextEditingController();
                DateTime postedTimestamp;
                newPost.title = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    surfaceTintColor: userChosenAccent,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    title: const Center(
                      child: Text("What is this post about?"),
                    ),
                    content: TextFormField(
                      controller: postNameController,
                      decoration: const InputDecoration(
                        hintText: "Post title",
                      ),
                    ),
                    actions: [
                      TextButton(
                        style: ButtonStyle(
                          overlayColor: WidgetStatePropertyAll(
                            userChosenAccent.withOpacity(0.3),
                          ),
                          backgroundColor:
                              const WidgetStatePropertyAll(Colors.transparent),
                          foregroundColor:
                              WidgetStatePropertyAll(userChosenAccent),
                          surfaceTintColor:
                              WidgetStatePropertyAll(userChosenAccent),
                        ),
                        onPressed: () {
                          Navigator.pop(context, postNameController.text);
                        },
                        child: const Text("Submit"),
                      )
                    ],
                  ),
                );
                newPost.body = await showDialog(
                  // ignore: use_build_context_synchronously
                  context: context,
                  builder: (context) => AlertDialog(
                    surfaceTintColor: userChosenAccent,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    title: const Center(
                      child: Text("Post your information!"),
                    ),
                    content: TextFormField(
                      controller: postBodyController,
                      decoration: const InputDecoration(
                        hintText: "Content goes here",
                      ),
                    ),
                    actions: [
                      TextButton(
                        style: ButtonStyle(
                          overlayColor: WidgetStatePropertyAll(
                            userChosenAccent.withOpacity(0.3),
                          ),
                          backgroundColor:
                              const WidgetStatePropertyAll(Colors.transparent),
                          foregroundColor:
                              WidgetStatePropertyAll(userChosenAccent),
                          surfaceTintColor:
                              WidgetStatePropertyAll(userChosenAccent),
                        ),
                        onPressed: () {
                          Navigator.pop(context, postBodyController.text);
                        },
                        child: const Text("Submit"),
                      )
                    ],
                  ),
                );

                postedTimestamp = DateTime.now();
                newPost.posted = postedTimestamp;
                newPost.poster =
                    "${currentUser.firstName} ${currentUser.lastName}";

                try {
                  DocumentReference<Map<String, dynamic>> docRef =
                      await FirebaseFirestore.instance.collection('posts').add({
                    'title': newPost.title,
                    'body': newPost.body,
                    'posted': newPost.posted.toIso8601String(),
                    'poster': newPost.poster,
                    'id': 'placeholder'
                  });

                  await docRef.update({'id': docRef.id});

                  // Refresh the list of events
                  setState(() {});
                } catch (e) {
                  debugPrint("Failed to add post: $e");
                }

                // Refresh the list of events
                setState(() {});
              },
              child: const Icon(Icons.add),
            )
          : null,
      backgroundColor: const Color.fromARGB(255, 2, 1, 1),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "Welcome, ${currentUser.firstName}!",
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: postsStream,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                        snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      color: Colors.purple,
                    );
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      Map<String, dynamic> postData = doc.data();
                      return PostCard(post: Post.fromJson(postData));
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
