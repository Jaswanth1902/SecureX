// ========================================
// MOBILE APP - SETTINGS SCREEN
// Manages user preferences and account actions
// ========================================

import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import '../services/user_service.dart';
import '../widgets/glass_container.dart';
import 'login_screen.dart';
import '../utils/constants.dart';

import 'package:provider/provider.dart'; // Add provider import
import '../services/theme_provider.dart'; // Add theme provider import
import '../main.dart'; // Import main.dart to access AuthWrapper

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  bool _notificationsEnabled = true;
  // bool _darkModeEnabled = false; // Managed by Provider now
  String _userName = 'User';
  String _userPhone = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final phone = await _userService.getPhone();
    final name = await _userService.getFullName();
    setState(() {
      _userPhone = (phone != null && phone.isNotEmpty && phone.toLowerCase() != 'undefined') 
          ? phone 
          : 'No Phone Number';
      _userName = (name != null && name.isNotEmpty) ? name : 'User';
    });
  }

  // ... (maintain existing helper methods)
  // Group settings sections
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Color iconBgColor,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconBgColor.withOpacity(0.1)),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailing != null) trailing else Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(bool value, Function(bool) onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: Colors.green.withOpacity(0.6),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.white.withOpacity(0.1),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222222), // Dark theme default
          title: const Text('Change Password', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final current = currentController.text;
                final newPass = newController.text;
                
                if (current.isEmpty || newPass.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                   );
                   return;
                }
                
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Updating password...'), duration: Duration(seconds: 1)),
                );

                final success = await _userService.changePassword(current, newPass);
                
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.green, content: Text('Password changed successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.red, content: Text('Failed: Incorrect current password or network error')),
                    );
                  }
                }
              },
              child: const Text('Change', style: TextStyle(color: Colors.pink)),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222222), // Dark theme default
          title: const Text('Send Feedback', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tell us what you think...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.pink, width: 2)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final message = controller.text.trim();
                if (message.isNotEmpty) {
                  // Show loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sending feedback...'), duration: Duration(seconds: 1)),
                  );
                  
                  final success = await _userService.sendFeedback(message);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor: Colors.green, content: Text('Feedback sent successfully!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor: Colors.red, content: Text('Failed to send feedback')),
                      );
                    }
                  }
                }
              },
              child: const Text('Send', style: TextStyle(color: Colors.pink)),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final controller = TextEditingController(text: _userName != 'User' ? _userName : '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Full Name',
              labelStyle: TextStyle(color: Colors.grey.shade400),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Save', style: TextStyle(color: Colors.pink)),
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Updating profile...'), duration: Duration(seconds: 1)),
                );
                
                final success = await _userService.updateProfile(newName);
                
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    setState(() {
                      _userName = newName;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.green, content: Text('Profile updated!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.red, content: Text('Failed to update profile')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // Get provider

    return Container(
      decoration: BoxDecoration(gradient: AppConstants.getBackgroundGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          automaticallyImplyLeading: true,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Text(
                'Manage your preferences',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          centerTitle: false,
          toolbarHeight: 80,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // Zen Tech Profile Card
            // Zen Tech Profile Card - Theme Aware
            _buildProfileCard(
              _userName,
              _userPhone,
              context,
              themeProvider.isDarkMode,
            ),
            
            // General Section
            _buildSectionHeader('General'),
            GlassContainer(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.lock,
                    title: 'Change Password',
                    iconBgColor: Colors.orange,
                    iconColor: Colors.orange.shade100,
                    onTap: () {
                      _showChangePasswordDialog(context);
                    },
                  ),
                  Divider(height: 1, color: Colors.white.withOpacity(0.1), indent: 16, endIndent: 16),
                  _buildSettingTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    iconBgColor: Colors.yellow,
                    iconColor: Colors.yellow.shade100,
                    trailing: _buildSwitch(_notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
                  ),
                  Divider(height: 1, color: Colors.white.withOpacity(0.1), indent: 16, endIndent: 16),
                  _buildSettingTile(
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    iconBgColor: Colors.purple,
                    iconColor: Colors.purple.shade100,
                    trailing: _buildSwitch(
                      themeProvider.isDarkMode, 
                      (v) => themeProvider.toggleTheme(v),
                    ),
                  ),
                ],
              ),
            ),

            // Support Section
            _buildSectionHeader('Support'),
            GlassContainer(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    iconBgColor: Colors.green,
                    iconColor: Colors.green.shade100,
                    onTap: () {},
                  ),
                  Divider(height: 1, color: Colors.white.withOpacity(0.1), indent: 16, endIndent: 16),
                  _buildSettingTile(
                    icon: Icons.feedback,
                    title: 'Feedback form',
                    iconBgColor: Colors.indigo,
                    iconColor: Colors.indigo.shade100,
                    onTap: () => _showFeedbackDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            // Logout Button
            GlassContainer(
              onTap: () {
                // 1. Perform logout logic (clear tokens, state)
                widget.onLogout();
                
                // 2. Navigate to AuthWrapper (Login) and remove all previous routes
                // This ensures we don't have to swipe back and the stack is cleared.
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                  (route) => false,
                );
              },
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.logout, color: Colors.red.shade100),
                   const SizedBox(width: 8),
                   Text(
                     'Log Out',
                     style: TextStyle(
                       color: Colors.red.shade100,
                       fontWeight: FontWeight.bold,
                       fontSize: 16,
                     ),
                   )
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  Widget _buildProfileCard(String name, String phone, BuildContext context, bool isDark) {
    // Zen Tech Palette (Mobile - Matches Desktop)
    final cardColor = isDark 
        ? const Color(0xFF1E293B).withOpacity(0.7) // Slate-800
        : Colors.white.withOpacity(0.85);
        
    final cardBorder = isDark 
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);

    final glowColor = isDark 
        ? const Color(0xFF38BDF8).withOpacity(0.15) // Soft Sky Blue
        : const Color(0xFF0EA5E9).withOpacity(0.1);

    final nameColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final shadowColor = isDark ? Colors.black26 : Colors.grey.withOpacity(0.1);

    // Soft Indigo Gradient (Muted for dark, pastel for light)
    final avatarGradient = LinearGradient(
      colors: isDark 
        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)] 
        : [const Color(0xFFA5B4FC), const Color(0xFFC4B5FD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Ambient Glow
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: glowColor,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor,
                          blurRadius: 50,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Squircle Avatar
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: avatarGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 20),
                      
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello,',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              style: TextStyle(
                                color: nameColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Phone Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone_android_rounded, size: 12, color: subTextColor),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      phone,
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Edit Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                             _showEditProfileDialog(context);
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300
                              ),
                              boxShadow: isDark ? [] : [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
