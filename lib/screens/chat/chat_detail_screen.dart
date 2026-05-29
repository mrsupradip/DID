import 'package:flutter/material.dart';

import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import '../../services/social_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatContact conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final SocialService _socialService = SocialService();

  ChatContact get conversation => widget.conversation;

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    if (conversation.isTeamChat) {
      setState(() {
        ChatService.sendMessage(conversationId: conversation.id, message: text);
      });
    } else {
      await _socialService.sendMessage(receiverUid: conversation.id, text: text);
    }

    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.greenAccent,
              child: Text(
                conversation.avatar,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(conversation.name),
                  Text(
                    conversation.role,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: conversation.isTeamChat
                ? _MessageList(
                    controller: scrollController,
                    messages: conversation.messages,
                    currentUid: 'me',
                  )
                : StreamBuilder<List<MessageModel>>(
                    stream: _socialService.streamMessagesWith(conversation.id),
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? conversation.messages;
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          messages.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return _MessageList(
                        controller: scrollController,
                        messages: messages,
                        currentUid: _socialService.currentUid ?? '',
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xff0B0F1A),
              border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Message ${conversation.name}',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xff1A2233),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.greenAccent,
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final ScrollController controller;
  final List<MessageModel> messages;
  final String currentUid;

  const _MessageList({
    required this.controller,
    required this.messages,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUid;
        return _MessageBubble(message: message, isMe: isMe);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? Colors.greenAccent : const Color(0xff1A2233),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.message,
          style: TextStyle(
            color: isMe ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
