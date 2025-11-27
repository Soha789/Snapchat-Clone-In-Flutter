import 'dart:typed_data'; // for Uint8List

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const SnapCloneApp());
}

/// Simple snap model (in-memory, stores bytes instead of File)
class Snap {
  final String id;
  final Uint8List bytes;
  final DateTime createdAt;

  Snap({
    required this.id,
    required this.bytes,
    required this.createdAt,
  });
}

class SnapCloneApp extends StatefulWidget {
  const SnapCloneApp({super.key});

  @override
  State<SnapCloneApp> createState() => _SnapCloneAppState();
}

class _SnapCloneAppState extends State<SnapCloneApp> {
  bool _loggedIn = false;
  final List<Snap> _snaps = [];

  void _handleLogin() {
    setState(() {
      _loggedIn = true;
    });
  }

  void _addSnap(Uint8List snapBytes) {
    setState(() {
      _snaps.add(
        Snap(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          bytes: snapBytes,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  /// Only snaps created within the last 24 hours are "active"
  List<Snap> get _activeSnaps {
    final now = DateTime.now();
    return _snaps
        .where((s) => now.difference(s.createdAt) <= const Duration(hours: 24))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapClone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: _loggedIn
          ? HomeScreen(
              snaps: _activeSnaps,
              onNewSnap: _addSnap,
            )
          : LoginScreen(onLogin: _handleLogin),
    );
  }
}

/// ---------- LOGIN SCREEN ----------

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fakeLogin() {
    // For now this just logs in without validating.
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.camera_alt,
                size: 80,
                color: Colors.yellow,
              ),
              const SizedBox(height: 24),
              const Text(
                "Welcome to SnapClone",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sign in to start sending snaps.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fakeLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              const Text(
                "This is a demo login (no real backend yet).",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- HOME SCREEN WITH BOTTOM NAV ----------

class HomeScreen extends StatefulWidget {
  final List<Snap> snaps;
  final Function(Uint8List) onNewSnap;

  const HomeScreen({
    super.key,
    required this.snaps,
    required this.onNewSnap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Center = Camera (like Snapchat)

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ChatsPage(),
      CameraPage(onNewSnap: widget.onNewSnap),
      StoriesPage(snaps: widget.snaps),
      const ProfilePage(),
    ];

    final titles = [
      "Chats",
      "Camera",
      "Stories",
      "Profile",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        centerTitle: true,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: "Camera",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: "Stories",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

/// ---------- CAMERA PAGE (CREATE SNAP) ----------

class CameraPage extends StatelessWidget {
  final Function(Uint8List) onNewSnap;

  const CameraPage({super.key, required this.onNewSnap});

  Future<void> _takeSnap(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
    );

    if (picked != null) {
      // Read bytes (works on web + mobile)
      final bytes = await picked.readAsBytes();
      onNewSnap(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Snap captured! Check Stories.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _takeSnap(context),
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: const Center(
            child: Icon(
              Icons.camera_alt,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- STORIES PAGE (VIEW SNAPS) ----------

class StoriesPage extends StatelessWidget {
  final List<Snap> snaps;

  const StoriesPage({super.key, required this.snaps});

  @override
  Widget build(BuildContext context) {
    if (snaps.isEmpty) {
      return const Center(
        child: Text(
          "No stories yet.\nCapture a snap to create one!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: snaps.length,
      itemBuilder: (context, index) {
        final snap = snaps[index];
        final age = DateTime.now().difference(snap.createdAt);
        final hoursLeft = 24 - age.inHours;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: MemoryImage(snap.bytes),
          ),
          title: const Text("My Story"),
          subtitle: Text(
            "Disappears in ${hoursLeft <= 0 ? 0 : hoursLeft}h",
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StoryViewerScreen(snap: snap),
              ),
            );
          },
        );
      },
    );
  }
}

class StoryViewerScreen extends StatelessWidget {
  final Snap snap;

  const StoryViewerScreen({super.key, required this.snap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(),
      body: Center(
        child: Image.memory(snap.bytes),
      ),
    );
  }
}

/// ---------- CHATS PAGE (DUMMY FOR NOW) ----------

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy static list of chats for now.
    final chats = [
      "Best Friend",
      "Study Group",
      "Snap Squad",
      "Family",
    ];

    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final name = chats[index];
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text(name),
          subtitle: const Text("Tap to open chat (demo)"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(friendName: name),
              ),
            );
          },
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String friendName;

  const ChatScreen({super.key, required this.friendName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<String> _messages = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(text);
      _controller.clear();
    });

    // Optional: Auto-delete messages after a short delay (demo "disappearing")
    Future.delayed(const Duration(seconds: 15), () {
      if (!mounted) return;
      setState(() {
        if (_messages.isNotEmpty) {
          _messages.removeAt(0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Send a disappearing message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- PROFILE PAGE (DUMMY) ----------

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 40),
          ),
          SizedBox(height: 12),
          Text(
            "Username (demo)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            "Streaks, trophies & settings will go here.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
