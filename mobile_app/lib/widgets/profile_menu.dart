import 'package:flutter/material.dart';
import 'profile_card.dart';
import '../services/user_service.dart';

class ProfileMenu extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfileMenu({super.key, required this.onLogout});

  Future<Map<String, String>> _getUserInfo() async {
    final userService = UserService();
    final phone = await userService.getPhone();
    final userId = await userService.getUserId();
    
    return {
      'name': 'User ${userId?.substring(0, 8) ?? ''}',
      'email': phone ?? 'Not available',
    };
  }

  void _showProfileCard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<Map<String, String>>(
        future: _getUserInfo(),
        builder: (context, snapshot) {
          final userInfo = snapshot.data ?? {'name': 'User', 'email': 'email@example.com'};
          
          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.5,
            maxChildSize: 0.85,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
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
                      userName: userInfo['name']!,
                      userEmail: userInfo['email']!,
                      onLogout: () {
                        Navigator.pop(context);
                        onLogout();
                      },
                      onEditProfile: () {
                        Navigator.pop(context);
                        // TODO: Navigate to edit profile screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit profile coming soon')),
                        );
                      },
                    ),
                    
                    // Additional menu items
                    _buildMenuTile(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to settings
                      },
                    ),
                    _buildMenuTile(
                      context,
                      icon: Icons.history_outlined,
                      title: 'Print History',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to history
                      },
                    ),
                    _buildMenuTile(
                      context,
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to help
                      },
                    ),
                    _buildMenuTile(
                      context,
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {
                        Navigator.pop(context);
                        // Show about dialog
                      },
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8A2BE2).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF8A2BE2), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
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
