import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../models/story_model.dart';
import '../../services/profile_service.dart';
import '../../services/social_service.dart';
import '../../services/story_service.dart';
import '../../utils/image_source.dart';
import '../chat/chat_screen.dart';
import '../feed/create_post_screen.dart';
import '../ideas/ideas_screen.dart';
import '../profile/profile_screen.dart';
import '../team_room/my_room_screen.dart';
import '../team_match/team_match_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final pages = const [
    HomePage(),
    IdeasScreen(),
    ChatScreen(),
    TeamMatchScreen(),
    MyRoomScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),
      resizeToAvoidBottomInset: true,
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bolt_outlined), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room_outlined),
            label: '',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final List<String> motivationalQuotes = const [
    'Build the thing they said was impossible.',
    'Ship small. Learn fast. Repeat.',
    'Your next commit can change everything.',
    'Consistency beats motivation.',
  ];

  ProfileData? profile;
  bool showWelcome = true;
  int quoteIndex = 0;
  Timer? welcomeTimer;
  Timer? quoteTimer;
  Timer? _storyRefreshTimer;
  late AnimationController dashboardController;
  final StoryService _storyService = StoryService();
  DateTime _storyCutoff = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _loadProfile();

    dashboardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    welcomeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => showWelcome = false);
      }
    });

    quoteTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        quoteIndex = (quoteIndex + 1) % motivationalQuotes.length;
      });
    });

    _storyRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        _storyCutoff = DateTime.now().toUtc();
      });
    });
  }

  @override
  void dispose() {
    welcomeTimer?.cancel();
    quoteTimer?.cancel();
    _storyRefreshTimer?.cancel();
    dashboardController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final loadedProfile = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() => profile = loadedProfile);
  }

  Widget _buildStoryStrip() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _storyService.watchActiveStories(cutoff: _storyCutoff),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SizedBox(
            height: 114,
            child: Row(
              children: [
                _CreateStoryBubble(onTap: _openCreateStorySheet),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Stories unavailable right now.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          );
        }

        final stories =
            snapshot.data?.docs
                .map((doc) => StoryModel.fromMap(doc.id, doc.data()))
                .where((story) => !story.isExpired && story.imageUrl.isNotEmpty)
                .toList() ??
            <StoryModel>[];

        stories.sort(
          (left, right) => right.timestamp.compareTo(left.timestamp),
        );

        final ownStories = stories
            .where((story) => story.userId == currentUid)
            .toList();
        final others = stories
            .where((story) => story.userId != currentUid)
            .toList();
        final visibleStories = [...ownStories, ...others];

        if (snapshot.connectionState == ConnectionState.waiting &&
            visibleStories.isEmpty) {
          return const SizedBox(
            height: 114,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final itemCount = visibleStories.length + (ownStories.isEmpty ? 1 : 0);

        return SizedBox(
          height: 114,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (ownStories.isEmpty && index == 0) {
                return _CreateStoryBubble(onTap: _openCreateStorySheet);
              }

              final storyIndex = ownStories.isEmpty ? index - 1 : index;
              final story = visibleStories[storyIndex];
              return _InstagramStoryBubble(
                story: story,
                isMine: story.userId == currentUid,
                onTap: () => _openStoryViewer(story),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openCreateStorySheet() async {
    final captionController = TextEditingController();
    final rootMessenger = ScaffoldMessenger.of(context);
    String? selectedImagePath;
    String? selectedImageName;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xff161E30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        bool uploading = false;
        bool closing = false;

        Future<void> pickImage(
          void Function(void Function()) setSheetState,
        ) async {
          final result = await FilePicker.pickFiles(
            allowMultiple: false,
            type: FileType.image,
            withData: false,
          );

          if (!sheetContext.mounted || result == null || result.files.isEmpty) {
            return;
          }

          final file = result.files.single;
          final path = file.path;
          if (path == null || path.isEmpty) {
            rootMessenger.showSnackBar(
              const SnackBar(content: Text('Unable to read selected image')),
            );
            return;
          }

          setSheetState(() {
            selectedImagePath = path;
            selectedImageName = file.name;
          });
        }

        Future<void> submitStory(
          void Function(void Function()) setSheetState,
        ) async {
          if (uploading || closing) return;

          final navigator = Navigator.of(sheetContext);
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            if (!sheetContext.mounted) return;
            rootMessenger.showSnackBar(
              const SnackBar(content: Text('Login required to create a story')),
            );
            return;
          }

          final imagePath = selectedImagePath;
          if (imagePath == null ||
              imagePath.isEmpty ||
              !File(imagePath).existsSync()) {
            if (!sheetContext.mounted) return;
            rootMessenger.showSnackBar(
              const SnackBar(content: Text('Choose a valid story image')),
            );
            return;
          }

          if (!sheetContext.mounted) return;
          setSheetState(() => uploading = true);

          try {
            final currentProfile = profile ?? ProfileData.defaultData();
            await _storyService.createStory(
              userId: user.uid,
              username: currentProfile.displayName,
              profileImage: currentProfile.profileImagePath,
              imagePath: imagePath,
              caption: captionController.text.trim(),
            );

            if (!sheetContext.mounted) return;

            closing = true;
            navigator.pop();
            if (mounted) {
              setState(() => _storyCutoff = DateTime.now().toUtc());
            }
            rootMessenger.showSnackBar(
              const SnackBar(content: Text('Story posted')),
            );
          } catch (error) {
            debugPrint('Story upload failed: $error');
            if (!sheetContext.mounted) return;
            rootMessenger.showSnackBar(
              SnackBar(content: Text('Failed to upload story: $error')),
            );
          } finally {
            // If we already started closing, don't try to mutate UI.
            if (sheetContext.mounted && !closing) {
              setSheetState(() => uploading = false);
            }
          }
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create story',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: captionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a caption',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xff1B2235),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: uploading
                              ? null
                              : () => pickImage(setSheetState),
                          icon: const Icon(Icons.image_outlined),
                          label: Text(
                            selectedImageName == null
                                ? 'Choose image'
                                : 'Image ready',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectedImagePath != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(selectedImagePath!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: uploading
                          ? null
                          : () => submitStory(setSheetState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: uploading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Share story'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    captionController.dispose();
  }

  Future<void> _openStoryViewer(StoryModel story) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => StoryViewerScreen(story: story),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = profile ?? ProfileData.defaultData();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        // Avoid adding extra constant bottom padding; the parent Scaffold
        // already reserves space for the bottom navigation bar.
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: _ProfileAvatar(profile: currentProfile, radius: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hay! Devian',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.96),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreatePostScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.create_rounded, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedPostsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bookmark_border, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppNotificationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: showWelcome
                  ? Container(
                      key: const ValueKey('welcome'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.greenAccent.withValues(alpha: 0.22),
                            Colors.lightBlueAccent.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Text(
                        'Ready to build something great?',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('welcome-hidden')),
            ),
            const SizedBox(height: 18),
            _buildStoryStrip(),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: dashboardController,
              builder: (context, _) {
                final scale = 1 + (dashboardController.value * 0.018);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xff161E30),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(
                            alpha: 0.08 + (dashboardController.value * 0.22),
                          ),
                          blurRadius: 14 + (dashboardController.value * 22),
                          spreadRadius: 1 + (dashboardController.value * 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                color: Colors.greenAccent.shade100,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.26),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.greenAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withValues(
                                      alpha:
                                          0.12 +
                                          (dashboardController.value * 0.24),
                                    ),
                                    blurRadius:
                                        10 + (dashboardController.value * 10),
                                    spreadRadius: dashboardController.value * 2,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Momentum',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Your build momentum',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Text(
                            motivationalQuotes[quoteIndex],
                            key: ValueKey(quoteIndex),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Live Feed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 12),
            const LiveFeedSection(limit: 5),
          ],
        ),
      ),
    );
  }
}

class LiveFeedSection extends StatelessWidget {
  final int? limit;

  const LiveFeedSection({super.key, this.limit});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xff161E30),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'No posts yet. Be the first to share.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final posts = snapshot.data!.docs;
        final visiblePosts = limit == null
            ? posts
            : posts.take(limit!).toList();

        return ListView.separated(
          itemCount: visiblePosts.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            return _XPostCard(doc: visiblePosts[index]);
          },
        );
      },
    );
  }
}

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Saved Posts'),
      ),
      body: SafeArea(
        child: uid == null
            ? const Center(
                child: Text(
                  'Login required',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('saves', arrayContains: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Saved posts are unavailable right now.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final posts = [...?snapshot.data?.docs];
                  posts.sort((left, right) {
                    final leftCreated = left.data()['createdAt'];
                    final rightCreated = right.data()['createdAt'];
                    final leftTime = leftCreated is Timestamp
                        ? leftCreated.toDate()
                        : DateTime.fromMillisecondsSinceEpoch(0);
                    final rightTime = rightCreated is Timestamp
                        ? rightCreated.toDate()
                        : DateTime.fromMillisecondsSinceEpoch(0);
                    return rightTime.compareTo(leftTime);
                  });

                  if (posts.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No saved posts yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    itemCount: posts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          _XPostCard(doc: posts[index]),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await posts[index].reference.update({
                                  'saves': FieldValue.arrayRemove([uid]),
                                });
                              },
                              icon: const Icon(Icons.bookmark_remove_outlined),
                              label: const Text('Remove from saved'),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class AppNotificationsScreen extends StatelessWidget {
  const AppNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SocialService();

    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: service.streamNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Notifications are unavailable right now.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return const Center(
                child: Text(
                  'No notifications yet.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = notifications[index];
                final data = doc.data();
                final type = (data['type'] ?? '').toString();
                final title = (data['title'] ?? 'Notification').toString();
                final body = (data['body'] ?? '').toString();
                final requestId = (data['requestId'] ?? '').toString();

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff1B2235),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _notificationIcon(type),
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                            if (type == 'friend_request' &&
                                requestId.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  await service.acceptFriendRequest(requestId);
                                  await doc.reference.update({'read': true});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Accept request'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'friend_request':
      case 'friend_accept':
        return Icons.person_add_alt_1;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'team_join':
        return Icons.groups_outlined;
      default:
        return Icons.notifications_none;
    }
  }
}

class _XPostCard extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _XPostCard({required this.doc});

  @override
  State<_XPostCard> createState() => _XPostCardState();
}

class _XPostCardState extends State<_XPostCard> {
  List<Map<String, dynamic>> _parseComments(Map<String, dynamic> post) {
    final raw = (post['comments'] as List<dynamic>? ?? <dynamic>[]);
    return raw
        .whereType<Map>()
        .map((entry) => entry.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  Future<void> _toggleArrayField(String field) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (field == 'likes' || field == 'dislikes') {
      await _toggleReaction(field, uid);
      return;
    }

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snapshot = await txn.get(widget.doc.reference);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final existing = (data[field] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList();

      txn.update(widget.doc.reference, {
        field: existing.contains(uid)
            ? FieldValue.arrayRemove([uid])
            : FieldValue.arrayUnion([uid]),
      });
    });
  }

  Future<void> _toggleReaction(String field, String uid) async {
    final opposite = field == 'likes' ? 'dislikes' : 'likes';

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snapshot = await txn.get(widget.doc.reference);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final existing = (data[field] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList();

      if (existing.contains(uid)) {
        txn.update(widget.doc.reference, {
          field: FieldValue.arrayRemove([uid]),
        });
      } else {
        txn.update(widget.doc.reference, {
          field: FieldValue.arrayUnion([uid]),
          opposite: FieldValue.arrayRemove([uid]),
        });
      }
    });
  }

  Future<void> _addComment() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add comment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Write comment'),
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
      final snapshot = await txn.get(widget.doc.reference);
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

      txn.update(widget.doc.reference, {
        'comments': comments,
        'commentUids': FieldValue.arrayUnion([uid]),
      });
    });
  }

  Future<void> _openCommentsSheet() async {
    final post = widget.doc.data();
    final comments = _parseComments(post);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff161E30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'No comments yet. Start the conversation.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                SizedBox(
                  height: 240,
                  child: ListView.separated(
                    itemCount: comments.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final item = comments[index];
                      final uid = (item['uid'] ?? '').toString();
                      final text = (item['text'] ?? '').toString();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uid.length > 10 ? uid.substring(0, 10) : uid,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await Future<void>.delayed(Duration.zero);
                    if (!mounted) return;
                    await _addComment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Add comment'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePost() async {
    await widget.doc.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.doc.data();
    final caption = (post['caption'] ?? '').toString();
    final author = (post['uid'] ?? 'developer').toString();
    final displayName = author.length > 10 ? author.substring(0, 10) : author;
    final attachmentName = post['attachmentName']?.toString();
    final attachmentType = post['attachmentType']?.toString();
    final attachmentUrl = post['attachmentUrl']?.toString();

    final likes = (post['likes'] as List<dynamic>? ?? []).length;
    final dislikes = (post['dislikes'] as List<dynamic>? ?? []).length;
    final saves = (post['saves'] as List<dynamic>? ?? []).length;
    final votes = (post['votes'] as List<dynamic>? ?? []).length;
    final comments = (post['comments'] as List<dynamic>? ?? []).length;
    final commentsList = _parseComments(post);

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null && author == currentUid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff161E30),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '@${displayName.toLowerCase()}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white54),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deletePost();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete post'),
                    ),
                  ],
                )
              else
                const Icon(Icons.more_horiz, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 14),
          if (attachmentType == 'photo' &&
              attachmentUrl != null &&
              attachmentUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  attachmentUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.black.withValues(alpha: 0.22),
                    alignment: Alignment.center,
                    child: const Text(
                      'Image unavailable',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ] else ...[
            if (caption.isNotEmpty)
              Text(
                caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
          ],
          if (attachmentType != 'photo' &&
              attachmentName != null &&
              attachmentName.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      attachmentName,
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              _ActionButton(
                icon: Icons.thumb_up_alt_outlined,
                label: 'Like $likes',
                onTap: () => _toggleArrayField('likes'),
              ),
              _ActionButton(
                icon: Icons.how_to_vote_outlined,
                label: 'Vote $votes',
                onTap: () => _toggleArrayField('votes'),
              ),
              _ActionButton(
                icon: Icons.mode_comment_outlined,
                label: 'Comment $comments',
                onTap: _openCommentsSheet,
              ),
              if (!isOwner) ...[
                _ActionButton(
                  icon: Icons.repeat_rounded,
                  label: 'Share',
                  onTap: () => _toggleArrayField('shares'),
                ),
                _ActionButton(
                  icon: Icons.thumb_down_alt_outlined,
                  label: 'Dislike $dislikes',
                  onTap: () => _toggleArrayField('dislikes'),
                ),
                _ActionButton(
                  icon: Icons.bookmark_border,
                  label: 'Save $saves',
                  onTap: () => _toggleArrayField('saves'),
                ),
              ],
            ],
          ),
          if (commentsList.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _openCommentsSheet,
              child: Text(
                'View all $comments comments',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              commentsList.last['text']?.toString() ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StoryItem {
  final String id;
  final String ownerId;
  final String name;
  final String mood;
  final String emoji;
  final Color color;
  final String? imagePath;
  final String? musicLink;
  final String? musicLabel;
  final bool isMine;
  final List<_StoryViewer> viewers;
  final DateTime expiresAt;

  _StoryItem({
    this.id = '',
    this.ownerId = '',
    required this.name,
    required this.mood,
    required this.emoji,
    required this.color,
    this.imagePath,
    this.musicLink,
    this.musicLabel,
    this.isMine = false,
    List<_StoryViewer>? viewers,
  }) : viewers = viewers ?? <_StoryViewer>[],
       expiresAt = DateTime.now().add(const Duration(hours: 8));

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mood': mood,
      'emoji': emoji,
      'color': color.toARGB32(),
      'imagePath': imagePath,
      'musicLink': musicLink,
      'musicLabel': musicLabel,
      'viewers': viewers
          .map((viewer) => {'name': viewer.name, 'liked': viewer.liked})
          .toList(),
    };
  }

  // ignore: unused_element
  factory _StoryItem.fromMap(
    String id,
    Map<String, dynamic> map,
    String currentUid,
  ) {
    final rawViewers = (map['viewers'] as List<dynamic>? ?? <dynamic>[]);
    final viewers = rawViewers
        .whereType<Map>()
        .map(
          (entry) => _StoryViewer(
            name: (entry['name'] ?? '').toString(),
            liked: (entry['liked'] ?? false) == true,
          ),
        )
        .toList();

    final ownerId = (map['ownerId'] ?? '').toString();

    return _StoryItem(
      id: id,
      ownerId: ownerId,
      name: (map['name'] ?? 'Story').toString(),
      mood: (map['mood'] ?? '').toString(),
      emoji: (map['emoji'] ?? '🙂').toString(),
      color: Color((map['color'] as int?) ?? Colors.greenAccent.toARGB32()),
      imagePath: map['imagePath']?.toString(),
      musicLink: map['musicLink']?.toString(),
      musicLabel: map['musicLabel']?.toString(),
      isMine: ownerId == currentUid,
      viewers: viewers,
    );
  }

  int get seenCount => viewers.length;

  int get likeCount => viewers.where((viewer) => viewer.liked).length;
}

class _StoryViewer {
  final String name;
  bool liked;

  _StoryViewer({required this.name, required this.liked});
}

class _MusicTrack {
  final String title;
  final String artist;
  final String link;

  _MusicTrack({required this.title, required this.artist, required this.link});
}

extension on _HomePageState {
  // ignore: unused_element
  Future<_MusicTrack?> _openMusicLibrarySheet() async {
    final controller = TextEditingController(text: 'Top hits');
    _MusicTrack? selection;

    selection = await showModalBottomSheet<_MusicTrack>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff161E30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        List<_MusicTrack> tracks = [];
        bool loading = false;
        String? error;
        bool initialSearchScheduled = false;

        Future<void> runSearch(
          void Function(void Function()) setSheetState,
        ) async {
          final query = controller.text.trim();
          if (query.isEmpty) return;
          setSheetState(() {
            loading = true;
            error = null;
          });

          try {
            final results = await _searchOpenMusicTracks(query);
            if (!sheetContext.mounted) return;
            setSheetState(() {
              tracks = results;
            });
          } catch (_) {
            if (!sheetContext.mounted) return;
            setSheetState(() {
              error = 'Unable to load music. Try again.';
            });
          } finally {
            if (sheetContext.mounted) {
              setSheetState(() {
                loading = false;
              });
            }
          }
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (!initialSearchScheduled) {
              initialSearchScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!sheetContext.mounted) return;
                if (!loading && tracks.isEmpty) {
                  runSearch(setSheetState);
                }
              });
            }
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Music library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search songs or artists',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xff1B2235),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        onPressed: loading
                            ? null
                            : () => runSearch(setSheetState),
                        icon: const Icon(Icons.search, color: Colors.white70),
                      ),
                    ),
                    onSubmitted: (_) => runSearch(setSheetState),
                  ),
                  const SizedBox(height: 12),
                  if (loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  else if (tracks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No tracks found. Try another search.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: tracks.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: Colors.white12),
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return ListTile(
                            onTap: () => Navigator.of(
                              sheetContext,
                              rootNavigator: true,
                            ).pop(track),
                            title: Text(
                              track.title,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              track.artist,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: const Icon(
                              Icons.music_note,
                              color: Colors.greenAccent,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    controller.dispose();
    return selection;
  }

  Future<List<_MusicTrack>> _searchOpenMusicTracks(String query) async {
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': query,
      'entity': 'song',
      'limit': '20',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) return <_MusicTrack>[];

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];

    return results
        .map((item) {
          final map = item as Map<String, dynamic>;
          final trackName = (map['trackName'] ?? '').toString();
          final artist = (map['artistName'] ?? '').toString();
          final previewUrl = (map['previewUrl'] ?? '').toString();
          final trackViewUrl = (map['trackViewUrl'] ?? '').toString();
          final link = previewUrl.isNotEmpty ? previewUrl : trackViewUrl;

          return _MusicTrack(title: trackName, artist: artist, link: link);
        })
        .where((track) {
          return track.title.isNotEmpty &&
              track.artist.isNotEmpty &&
              track.link.isNotEmpty;
        })
        .toList();
  }
}

class _CreateStoryBubble extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateStoryBubble({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StoryBubble extends StatelessWidget {
  final _StoryItem story;
  final VoidCallback onTap;

  const _StoryBubble({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [story.color, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xff101522),
                child: Text(story.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              story.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              '${story.seenCount} seen • ${story.likeCount} likes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstagramStoryBubble extends StatelessWidget {
  final StoryModel story;
  final bool isMine;
  final VoidCallback onTap;

  const _InstagramStoryBubble({
    required this.story,
    required this.isMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profileImageProvider = resolveImageProvider(story.profileImage);
    final hasProfileImage = profileImageProvider != null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isMine
                          ? [Colors.greenAccent, Colors.lightBlueAccent]
                          : [Colors.pinkAccent, Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      story.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xff101522),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xff101522),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.white12,
                      backgroundImage: profileImageProvider,
                      child: hasProfileImage
                          ? null
                          : Text(
                              story.username.isEmpty
                                  ? 'D'
                                  : story.username
                                        .substring(0, 1)
                                        .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              story.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              '24h story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryViewerScreen extends StatelessWidget {
  final StoryModel story;

  const StoryViewerScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final hasProfileImage = resolveImageProvider(story.profileImage) != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                story.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Text(
                    'Story unavailable',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white12,
                    backgroundImage: resolveImageProvider(story.profileImage),
                    child: hasProfileImage
                        ? null
                        : Text(
                            story.username.isEmpty
                                ? 'D'
                                : story.username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          story.caption ?? 'Story',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final ProfileData profile;
  final double radius;

  const _ProfileAvatar({required this.profile, required this.radius});

  @override
  Widget build(BuildContext context) {
    final imagePath = profile.profileImagePath;
    final imageProvider = resolveImageProvider(imagePath);
    final hasImage = imageProvider != null;
    final initials = profile.displayName.isEmpty
        ? 'D'
        : profile.displayName
              .split(' ')
              .where((part) => part.isNotEmpty)
              .map((part) => part.substring(0, 1).toUpperCase())
              .take(2)
              .join();

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.greenAccent, width: 1.5),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xff1B2235),
        backgroundImage: imageProvider,
        child: hasImage
            ? null
            : Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class _QuickInputDialog extends StatefulWidget {
  final String title;
  final String hint;

  const _QuickInputDialog({required this.title, required this.hint});

  @override
  State<_QuickInputDialog> createState() => _QuickInputDialogState();
}

class _QuickInputDialogState extends State<_QuickInputDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
