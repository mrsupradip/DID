import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
  String? attachmentName;
  String? attachmentPath;
  String? attachmentType;

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment({required bool isPhoto}) async {
    if (loading) return;
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: isPhoto ? FileType.image : FileType.any,
      withData: false,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    setState(() {
      attachmentName = file.name;
      attachmentPath = file.path;
      attachmentType = isPhoto ? 'photo' : 'project';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        title: const Text("Create Post"),
      ),

      body: SingleChildScrollView(
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

            const SizedBox(height: 16),

            if (attachmentName != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff1B2235),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      attachmentType == 'photo' ? Icons.image : Icons.code,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        attachmentName!,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          attachmentName = null;
                          attachmentPath = null;
                          attachmentType = null;
                        });
                      },
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ),

            if (attachmentType == 'photo' && attachmentPath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(attachmentPath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xff1B2235),
                    child: const Text(
                      'Unable to preview this image',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAttachment(isPhoto: true),
                    icon: const Icon(Icons.image),
                    label: const Text('Photo'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAttachment(isPhoto: false),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Project'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        FocusScope.of(context).unfocus();
                        final messenger = ScaffoldMessenger.of(context);

                        final text = captionController.text.trim();
                        if (text.isEmpty && attachmentName == null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Add text or an attachment'),
                            ),
                          );
                          return;
                        }

                        if (attachmentType == 'photo') {
                          final path = attachmentPath ?? '';
                          if (path.isEmpty || !File(path).existsSync()) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Re-select the photo to upload'),
                              ),
                            );
                            return;
                          }
                        }

                        if (loading || !mounted) return;
                        setState(() {
                          loading = true;
                        });

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) throw Exception('Not signed in');

                          await postService.createPost(
                            uid: user.uid,
                            caption: text,
                            attachmentName: attachmentName,
                            attachmentPath: attachmentPath,
                            attachmentType: attachmentType,
                          );

                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Post created')),
                          );

                          navigator.pop();
                        } catch (e) {
                          debugPrint('Failed to create post: $e');
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to create post: $e'),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              loading = false;
                            });
                          }
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
