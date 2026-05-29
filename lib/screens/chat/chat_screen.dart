import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'chat_detail_screen.dart';
import '../../services/chat_service.dart';
import '../../services/social_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SocialService _socialService = SocialService();
  String query = '';

  Future<void> _showAddFriendDialog() async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    var adding = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xff101522),
              title: const Text('Add friend'),
              content: TextField(
                controller: controller,
                enabled: !adding,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'GitHub id or D!D user id',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: adding
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: adding
                      ? null
                      : () async {
                          final value = controller.text.trim();
                          if (value.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Enter a GitHub id or user id'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => adding = true);
                          try {
                            final user = await _socialService.findUserById(
                              value,
                            );
                            final message = await _socialService
                                .sendFriendRequest(user);
                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.pop(dialogContext, true);
                            messenger.showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                            setState(() {});
                          } catch (error) {
                            if (!mounted || !dialogContext.mounted) return;
                            setDialogState(() => adding = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                  child: adding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();

    final friends = ChatService.friends.where((conversation) {
      if (normalized.isEmpty) return true;
      return conversation.name.toLowerCase().contains(normalized) ||
          conversation.role.toLowerCase().contains(normalized) ||
          conversation.lastMessage.toLowerCase().contains(normalized);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xff101522),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat-add-fab',
        backgroundColor: Colors.greenAccent,
        onPressed: _showAddFriendDialog,
        child: const Icon(Icons.person_add_alt_1, color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: (value) => setState(() => query = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name, role, or message',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xff1A2233),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<List<ChatContact>>(
                  stream: _socialService.streamFriends(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Chats are unavailable right now.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final firestoreFriends = snapshot.data ?? <ChatContact>[];
                    final merged = <String, ChatContact>{};
                    for (final friend in [...firestoreFriends, ...friends]) {
                      merged[friend.id] = friend;
                    }

                    final visibleFriends = merged.values.where((conversation) {
                      if (normalized.isEmpty) return true;
                      return conversation.name.toLowerCase().contains(
                            normalized,
                          ) ||
                          conversation.role.toLowerCase().contains(
                            normalized,
                          ) ||
                          conversation.lastMessage.toLowerCase().contains(
                            normalized,
                          );
                    }).toList();

                    if (visibleFriends.isEmpty) {
                      return const _EmptyChatState();
                    }

                    return ListView(
                      children: [
                        const Text(
                          'Friends',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...visibleFriends.map(
                          (conversation) => ChatTile(
                            conversation: conversation,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    conversation: conversation,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xff1A2233),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              color: Colors.greenAccent,
              size: 56,
            ),
            const SizedBox(height: 12),
            const Text(
              'No friends yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can message only your friends. Add one to start chatting.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatTile extends StatelessWidget {
  final ChatContact conversation;
  final VoidCallback onTap;

  const ChatTile({super.key, required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xff1A2233),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.greenAccent,
              child: Text(
                conversation.avatar,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (conversation.isTeamChat)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Team',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatTime(conversation.lastMessageTime),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final hours = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minutes = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hours:$minutes $period';
  }
}
