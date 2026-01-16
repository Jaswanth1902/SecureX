import 'package:flutter/material.dart';
import 'profile_card.dart';
import 'edit_name_dialog.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';

typedef TabSwitchCallback = void Function(int index);


class ProfileMenu extends StatelessWidget {
  final VoidCallback onLogout;
  final TabSwitchCallback? onTabSwitch;

  const ProfileMenu({super.key, required this.onLogout, this.onTabSwitch});

  // Helper for menu tiles in the bottom sheet
  Widget _buildMenuTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8A2BE2)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }


  Future<Map<String, dynamic>> _getUserInfoAndStats() async {
    final userService = UserService();
    final apiService = ApiService();
    final fullName = await userService.getFullName();
    final phone = await userService.getPhone();
    // Fetch all files for stats
    int uploads = 0;
    int prints = 0;
    int completed = 0;
    try {
      final files = await apiService.listFiles();
      uploads = files.length;
      prints = files.where((f) => f.isPrinted == true).length;
      completed = files.where((f) => f.status == 'PRINT_COMPLETED').length;
    } catch (_) {}
    return {
      'name': (fullName != null && fullName.trim().isNotEmpty) ? fullName.trim() : 'User',
      'email': (phone ?? '').trim(),
      'uploads': uploads,
      'prints': prints,
      'completed': completed,
    };
  }

  void _showProfileCard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: _getUserInfoAndStats(),
        builder: (context, snapshot) {
          final userInfo = snapshot.data ?? {'name': 'User', 'email': 'email@example.com', 'uploads': 0, 'prints': 0, 'completed': 0};
          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.5,
            maxChildSize: 0.85,
            builder: (context, scrollController) => _ProfileCardSheet(
              userInfo: userInfo,
              onLogout: onLogout,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF8A2BE2), Color(0xFFBA55D3)],
          ),
        ),
        child: const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.person,
            size: 18,
            color: Color(0xFF8A2BE2),
          ),
        ),
      ),
      onPressed: () => _showProfileCard(context),
      tooltip: 'Profile',
    );
  }

}

// Top-level helper so nested sheet can reuse tiles
Widget _menuTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
  return ListTile(
    leading: Icon(icon, color: const Color(0xFF8A2BE2)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
    onTap: onTap,
  );
}

class _ProfileCardSheet extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  final VoidCallback onLogout;
  const _ProfileCardSheet({required this.userInfo, required this.onLogout});

  @override
  State<_ProfileCardSheet> createState() => _ProfileCardSheetState();
}

class _ProfileCardSheetState extends State<_ProfileCardSheet> {
  late String _name;
  final UserService _userService = UserService();

  void _onFullNameChanged() {
    final name = _userService.fullNameNotifier.value;
    if (!mounted) return;
    setState(() {
      _name = (name != null && name.trim().isNotEmpty) ? name.trim() : 'User';
    });
  }

  @override
  void initState() {
    super.initState();
    _name = widget.userInfo['name'] ?? 'User';
    // Subscribe to full name changes so this sheet updates immediately
    _userService.fullNameNotifier.addListener(_onFullNameChanged);
  }

  void _editName() async {
    final userService = UserService();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => EditNameDialog(
        initialName: _name,
        onNameChanged: (name) {
          Navigator.of(ctx).pop(name);
        },
      ),
    );
    if (newName != null && newName.trim().isNotEmpty && newName != _name) {
      await userService.updateFullName(newName.trim());
      setState(() {
        _name = newName.trim();
      });
    }
  }

  @override
  void dispose() {
    _userService.fullNameNotifier.removeListener(_onFullNameChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = widget.userInfo;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Profile Card
            ProfileCard(
              userName: _name,
              userEmail: userInfo['email'] ?? 'email@example.com',
              onLogout: () {
                Navigator.pop(context);
                widget.onLogout();
              },
              onEditProfile: _editName,
              uploads: userInfo['uploads'] ?? 0,
              prints: userInfo['prints'] ?? 0,
              completed: userInfo['completed'] ?? 0,
            ),
            // Additional menu items
            ...[
              _menuTile(
                context,
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Help & Support'),
                      content: const Text('Contact support@secureprint.com for help.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _menuTile(
                context,
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('About'),
                      content: const Text('SecurePrint Mobile App v1.0.0'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _menuTile(
                context,
                icon: Icons.logout,
                title: 'Logout',
                onTap: () {
                  Navigator.pop(context);
                  widget.onLogout();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// stray top-level build removed — `ProfileMenu` provides the icon button via its
// own `build` method above. This file now contains only widget classes.
