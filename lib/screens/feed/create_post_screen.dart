import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/post_firestore_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController captionController = TextEditingController();

  final PostFirestoreService postService = PostFirestoreService();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        title: const Text("Create Post"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: captionController,

              maxLines: 6,

              style: const TextStyle(color: Colors.white),

              decoration: InputDecoration(
                hintText: "What's happening in D!D?",

                hintStyle: const TextStyle(color: Colors.grey),

                filled: true,

                fillColor: const Color(0xff1B2235),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),

                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () async {
                  FocusScope.of(context).unfocus();

                  final text = captionController.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a caption')),
                    );
                    return;
                  }

                  setState(() {
                    loading = true;
                  });

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) throw Exception('Not signed in');

                    await postService.createPost(uid: user.uid, caption: text);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post created')),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create post: $e')),
                    );
                  } finally {
                    setState(() {
                      loading = false;
                    });
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,

                  padding: const EdgeInsets.all(18),
                ),

                child: loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Post",

                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
