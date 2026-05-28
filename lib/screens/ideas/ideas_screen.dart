import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IdeasScreen extends StatefulWidget {
  const IdeasScreen({super.key});

  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  final CollectionReference<Map<String, dynamic>> _quizPostsRef =
      FirebaseFirestore.instance.collection('quiz_posts');
  bool _creatingQuizPost = false;

  Future<void> _createQuizPost() async {
    if (_creatingQuizPost) return;

    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final tagsController = TextEditingController();

    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create quiz post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subtitleController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  hintText: 'Tags (comma separated)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, {
                'title': titleController.text.trim(),
                'subtitle': subtitleController.text.trim(),
                'tags': tagsController.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList(),
              });
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );

    titleController.dispose();
    subtitleController.dispose();
    tagsController.dispose();

    if (!mounted || data == null) return;
    final title = (data['title'] ?? '').toString();
    final subtitle = (data['subtitle'] ?? '').toString();
    final tags = (data['tags'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    if (title.isEmpty || subtitle.isEmpty || tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill title, description, and tags')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to create quiz post')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _creatingQuizPost = true;
      });
    }

    try {
      await _quizPostsRef.add({
        'uid': uid,
        'title': title,
        'subtitle': subtitle,
        'tags': tags,
        'votes': <String>[],
        'likes': <String>[],
        'dislikes': <String>[],
        'comments': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz post created')),
      );
    } catch (error) {
      debugPrint('Create quiz post failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create quiz post: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creatingQuizPost = false;
        });
      }
    }
  }

  Future<void> _addComment(DocumentReference<Map<String, dynamic>> ref) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Comment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Write your comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Post'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (!mounted || text == null || text.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? <String, dynamic>{};
      final commentsRaw = data['comments'] as List<dynamic>?;
      final comments = commentsRaw == null
          ? <Map<String, dynamic>>[]
          : commentsRaw
                .whereType<Map>()
                .map((entry) => entry.map((k, v) => MapEntry('$k', v)))
                .toList();

      comments.add({
        'uid': uid,
        'text': text,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      txn.update(ref, {'comments': comments});
    });
  }

  Future<void> _toggleArrayField({
    required DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> data,
    required String field,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final existing = (data[field] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    if (existing.contains(uid)) {
      await ref.update({
        field: FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        field: FieldValue.arrayUnion([uid]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),
      floatingActionButton: FloatingActionButton(
        heroTag: 'ideas-add-fab',
        onPressed: _creatingQuizPost ? null : _createQuizPost,
        backgroundColor: Colors.greenAccent,
        child: _creatingQuizPost
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add, color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ideas & Quiz Posts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only user-created quiz posts appear here.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _quizPostsRef
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No quiz posts yet. Create the first one.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();

                        final tags = (data['tags'] as List<dynamic>? ?? [])
                            .map((e) => e.toString())
                            .toList();
                        final votes =
                            (data['votes'] as List<dynamic>? ?? []).length;
                        final likes =
                            (data['likes'] as List<dynamic>? ?? []).length;
                        final dislikes =
                            (data['dislikes'] as List<dynamic>? ?? []).length;
                        final comments =
                            (data['comments'] as List<dynamic>? ?? []).length;

                        return _IdeaCard(
                          title: (data['title'] ?? '').toString(),
                          subtitle: (data['subtitle'] ?? '').toString(),
                          tags: tags,
                          votes: votes,
                          likes: likes,
                          dislikes: dislikes,
                          comments: comments,
                          onVote: () => _toggleArrayField(
                            ref: doc.reference,
                            data: data,
                            field: 'votes',
                          ),
                          onLike: () => _toggleArrayField(
                            ref: doc.reference,
                            data: data,
                            field: 'likes',
                          ),
                          onDislike: () => _toggleArrayField(
                            ref: doc.reference,
                            data: data,
                            field: 'dislikes',
                          ),
                          onComment: () => _addComment(doc.reference),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdeaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> tags;
  final int votes;
  final int likes;
  final int dislikes;
  final int comments;
  final VoidCallback onVote;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onComment;

  const _IdeaCard({
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.votes,
    required this.likes,
    required this.dislikes,
    required this.comments,
    required this.onVote,
    required this.onLike,
    required this.onDislike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff1A2233),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.greenAccent.withValues(alpha: 0.12),
                    labelStyle: const TextStyle(color: Colors.greenAccent),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionPill(label: 'Vote $votes', onTap: onVote),
              _ActionPill(label: 'Like $likes', onTap: onLike),
              _ActionPill(label: 'Dislike $dislikes', onTap: onDislike),
              _ActionPill(label: 'Comment $comments', onTap: onComment),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }
}
