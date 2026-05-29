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

    final questionController = TextEditingController();
    final optionControllers = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
    ];

    setState(() => _creatingQuizPost = true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: const Color(0xff101522),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          var posting = false;
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> addOption() async {
                setSheetState(() {
                  optionControllers.add(TextEditingController());
                });
              }

              void removeOption(int index) {
                if (optionControllers.length <= 2) return;
                final controller = optionControllers.removeAt(index);
                controller.dispose();
                setSheetState(() {});
              }

              Future<void> submitPoll() async {
                if (posting) return;

                final question = questionController.text.trim();
                final options = optionControllers
                    .map((controller) => controller.text.trim())
                    .where((option) => option.isNotEmpty)
                    .toList();

                if (question.isEmpty || options.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add a question and at least two options'),
                    ),
                  );
                  return;
                }

                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login required to create a poll'),
                    ),
                  );
                  return;
                }

                setSheetState(() => posting = true);
                try {
                  await _quizPostsRef.add({
                    'uid': uid,
                    'question': question,
                    'options': options
                        .asMap()
                        .entries
                        .map(
                          (entry) => {
                            'id':
                                'option_${DateTime.now().microsecondsSinceEpoch}_${entry.key}',
                            'text': entry.value,
                            'votes': 0,
                          },
                        )
                        .toList(),
                    'votedBy': <String>[],
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Poll posted')),
                    );
                  }
                } catch (error) {
                  debugPrint('Create poll failed: $error');
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to post poll: $error')),
                  );
                } finally {
                  if (sheetContext.mounted) {
                    setSheetState(() => posting = false);
                  }
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 18,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create poll',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: questionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ask a question',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xff1A2233),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...optionControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Option ${index + 1}',
                                    hintStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xff1A2233),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              if (optionControllers.length > 2) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: posting
                                      ? null
                                      : () => removeOption(index),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: posting ? null : addOption,
                        icon: const Icon(Icons.add, color: Colors.greenAccent),
                        label: const Text('Add option'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: posting ? null : submitPoll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.all(16),
                          ),
                          child: posting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Post poll'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      for (final controller in optionControllers) {
        controller.dispose();
      }
      questionController.dispose();
      if (mounted) {
        setState(() => _creatingQuizPost = false);
      }
    }
  }

  Future<void> _voteOnPoll({
    required DocumentReference<Map<String, dynamic>> ref,
    required String optionId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final votedBy = (data['votedBy'] as List<dynamic>? ?? <dynamic>[])
          .map((entry) => entry.toString())
          .toList();
      if (votedBy.contains(uid)) return;

      final options = (data['options'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map>()
          .map((entry) {
            final map = entry.map((key, value) => MapEntry('$key', value));
            return _PollOption.fromMap(map);
          })
          .toList();

      final updatedOptions = options.map((option) {
        if (option.id != optionId) return option;
        return option.copyWith(votes: option.votes + 1);
      }).toList();

      txn.update(ref, {
        'options': updatedOptions.map((option) => option.toMap()).toList(),
        'votedBy': FieldValue.arrayUnion([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xff101522),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomInset + 72),
        child: FloatingActionButton(
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
                          'No polls yet. Create the first one.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();

                        final options =
                            (data['options'] as List<dynamic>? ?? <dynamic>[])
                                .whereType<Map>()
                                .map((entry) {
                                  final map = entry.map(
                                    (key, value) => MapEntry('$key', value),
                                  );
                                  return _PollOption.fromMap(map);
                                })
                                .toList();
                        final votedBy =
                            (data['votedBy'] as List<dynamic>? ?? <dynamic>[])
                                .map((entry) => entry.toString())
                                .toList();
                        final currentUid =
                            FirebaseAuth.instance.currentUser?.uid;
                        final hasVoted =
                            currentUid != null && votedBy.contains(currentUid);
                        final totalVotes = options.fold<int>(
                          0,
                          (total, option) => total + option.votes,
                        );

                        return _PollCard(
                          question: (data['question'] ?? '').toString(),
                          options: options,
                          totalVotes: totalVotes,
                          hasVoted: hasVoted,
                          onVote: hasVoted
                              ? null
                              : (optionId) => _voteOnPoll(
                                  ref: doc.reference,
                                  optionId: optionId,
                                ),
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

class _PollCard extends StatelessWidget {
  final String question;
  final List<_PollOption> options;
  final int totalVotes;
  final bool hasVoted;
  final Future<void> Function(String optionId)? onVote;

  const _PollCard({
    required this.question,
    required this.options,
    required this.totalVotes,
    required this.hasVoted,
    required this.onVote,
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
          const Text(
            'Poll',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PollOptionTile(
                option: option,
                totalVotes: totalVotes,
                voted: hasVoted,
                onTap: onVote == null ? null : () => onVote!(option.id),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            totalVotes == 0
                ? 'Tap an option to vote'
                : '$totalVotes vote${totalVotes == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PollOption {
  final String id;
  final String text;
  final int votes;

  const _PollOption({
    required this.id,
    required this.text,
    required this.votes,
  });

  factory _PollOption.fromMap(Map<String, dynamic> data) {
    return _PollOption(
      id: (data['id'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      votes: (data['votes'] is num) ? (data['votes'] as num).toInt() : 0,
    );
  }

  _PollOption copyWith({String? id, String? text, int? votes}) {
    return _PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      votes: votes ?? this.votes,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'text': text, 'votes': votes};
  }
}

class _PollOptionTile extends StatelessWidget {
  final _PollOption option;
  final int totalVotes;
  final bool voted;
  final VoidCallback? onTap;

  const _PollOptionTile({
    required this.option,
    required this.totalVotes,
    required this.voted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalVotes == 0 ? 0.0 : option.votes / totalVotes;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xff141B2B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: voted
                ? Colors.greenAccent.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    option.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${option.votes}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
