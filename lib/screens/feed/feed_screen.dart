import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        title: const Text("D!D Feed"),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("posts")
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                "No Posts Yet",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'No posts yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: posts.length,

            itemBuilder: (context, index) {
              final post = posts[index];

              return Container(
                margin: const EdgeInsets.all(12),

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: const Color(0xff1B2235),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      post["caption"],

                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),

                    const SizedBox(height: 15),

                    if (post.data()["attachmentName"] != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xff111827),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${post["attachmentType"] ?? "file"}: ${post["attachmentName"]}',
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ),

                    if (post.data()["attachmentName"] != null)
                      const SizedBox(height: 15),

                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          color: Colors.white70,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          post["likes"].toString(),

                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
