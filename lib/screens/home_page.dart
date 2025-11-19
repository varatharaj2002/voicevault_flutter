import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';
import 'dictation_page.dart';
import 'view_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "User";
  String userEmail = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load saved user info from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_name') ?? "User";
    final savedEmail = prefs.getString('user_email') ?? "";

    if (!mounted) return;
    setState(() {
      userName = savedName;
      userEmail = savedEmail;
    });
  }

  /// Logout user and clear saved session
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  /// Show popup menu for “Your Audios” and “Logout”
  void _showMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(button.size.width, 40), ancestor: overlay),
        button.localToGlobal(Offset(button.size.width, 40), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          child: const Text("Your Audios"),
          onTap: () {
            Future.delayed(
              const Duration(milliseconds: 100),
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewPage(userEmail: userEmail),
                  ),
                );
              },
            );
          },
        ),
        PopupMenuItem(
          child: const Text("Logout"),
          onTap: () {
            Future.delayed(
              const Duration(milliseconds: 100),
                  () => _logout(),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showMenu,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/images/dummy_avatar.png'),
            ),
            const SizedBox(height: 20),
            Text(
              "Welcome, $userName 👋",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            /// Start Dictation button
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DictationPage(userEmail: userEmail),
                    ),
                  );
                },
                child: const Text(
                  "Start Dictation",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
