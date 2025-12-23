import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh profile data on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().refreshProfile();
    });
  }
  
  void _showEditNameDialog(BuildContext context, String currentName, bool isDark) {
    final TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E0A30) : Colors.white,
          title: Text('Edit Name', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Enter full name',
              hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade400),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.purple : Colors.purple)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  final success = await context.read<AuthService>().updateName(newName);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Name updated!' : 'Failed to update name')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final authService = context.watch<AuthService>();
    final isDark = themeService.isDarkMode;
    
    // Fetch user data safely
    final user = authService.user;
    final userName = user != null ? (user['full_name'] ?? 'User') : '...';
    final userEmail = user != null ? (user['email'] ?? '...') : '...';
    
    // Colors based on Light (previous) and Dark (new spec)
    final primaryColor = isDark ? const Color(0xFF6A0DAD) : const Color(0xFF8A2BE2);
    final bgGradientStart = isDark ? const Color(0xFF1E0A30) : const Color(0xFFF7F0FB);
    final bgGradientEnd = isDark ? const Color(0xFF3A1A5B) : const Color(0xFFEFFFFF);
    
    final textColor = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final labelColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade500;
    
    // Card styles
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5);
    final cardBorder = isDark ? Border.all(color: Colors.white.withOpacity(0.1)) : null;

    final sectionTitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E0A30).withOpacity(0.8) : Colors.transparent, // Backdrop blur simulation
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? const Color(0xFF2D1B4E) : Colors.white, // Darker circle in dark mode
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [themeService.colors.backgroundGradientStart, themeService.colors.backgroundGradientEnd]
                : [themeService.colors.backgroundGradientStart, const Color(0xFFE6E6FA), themeService.colors.backgroundGradientEnd], // Tri-color: Pink -> Lavender -> Blue
            stops: isDark ? null : [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // GENERAL SECTION
              _buildSectionTitle('GENERAL', sectionTitleColor),
              _buildCard(
                cardColor,
                border: cardBorder,
                children: [
                  _buildSwitchRow('Notifications', true, (val) {}, textColor, primaryColor),
                  _buildDivider(isDark),
                  _buildNavRow('Privacy Policy', textColor),
                ],
              ),
              const SizedBox(height: 24),

              // THEME TOGGLE (Standalone Card)
              _buildCard(
                cardColor,
                border: cardBorder,
                children: [
                  _buildSwitchRow(
                    'Toggle theme', 
                    themeService.isDarkMode, 
                    (val) => themeService.toggleTheme(val), 
                    textColor, 
                    primaryColor
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // PROFILE SECTION
              _buildSectionTitle('PROFILE', sectionTitleColor),
              _buildCard(
                cardColor,
                border: cardBorder,
                children: [
                  _buildProfileRow(
                    'Name', 
                    userName, 
                    textColor, 
                    labelColor, 
                    isDark, 
                    primaryColor,
                    onEdit: () => _showEditNameDialog(context, userName, isDark),
                  ),
                  _buildDivider(isDark),
                  _buildProfileRow(
                    'Email-id', 
                    userEmail, 
                    textColor, 
                    labelColor, 
                    isDark, 
                    primaryColor,
                    onEdit: null // Disable edit for email
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // DANGER ZONE
              _buildSectionTitle('DANGER ZONE', const Color(0xFFEF4444)),
              _buildCard(
                cardColor,
                border: cardBorder,
                children: [
                  _buildActionRow(
                    'Change password', 
                    textColor, 
                    _buildGradientButton('Change', primaryColor, onTap: null) // Disabled
                  ),
                  _buildDivider(isDark),
                  _buildActionRow(
                    'Delete account', 
                    textColor,
                    _buildDeleteButton(isDark, onTap: null), // Disabled
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Logout Button
              _buildLogoutButton(context, isDark),
              const SizedBox(height: 24),

              // ABOUT SECTION
              _buildSectionTitle('ABOUT', sectionTitleColor),
              _buildCard(
                cardColor,
                border: cardBorder,
                children: [
                   _buildInfoRow('Version', '1.0.0', textColor, isDark),
                   _buildDivider(isDark),
                   _buildNavRow('Send Feedback', textColor),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(Color bgColor, {BoxBorder? border, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchRow(String title, bool value, Function(bool) onChanged, Color textColor, Color activeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // p-4 equivalent
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, Color textColor, Color labelColor, bool isDark, Color primaryColor, {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: labelColor, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (onEdit != null)
             GestureDetector(
               onTap: onEdit,
               child: Icon(Icons.edit, size: 20, color: isDark ? const Color(0xFF9CA3AF).withOpacity(0.5) : primaryColor),
             ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String title, Color textColor, Widget actionButton) {
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          actionButton,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: TextStyle(
               color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
               fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(String text, Color primary, {VoidCallback? onTap}) {
    final bool isDisabled = onTap == null;
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, const Color(0xFFBA55D3)], 
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(bool isDark, {VoidCallback? onTap}) {
     final bool isDisabled = onTap == null;
     if (isDark) {
       return Opacity(
         opacity: isDisabled ? 0.5 : 1.0,
         child: Container(
           decoration: BoxDecoration(
             color: const Color(0xFF7F1D1D).withOpacity(0.4), // red-900/40
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)), // ring-red-500/50
           ),
           child: Material(
             color: Colors.transparent,
             child: InkWell(
               onTap: onTap,
               borderRadius: BorderRadius.circular(20),
               child: const Padding(
                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                 child: Text(
                   'Delete',
                   style: TextStyle(
                     color: Color(0xFFF87171), // red-400
                     fontWeight: FontWeight.w600,
                     fontSize: 13,
                   ),
                 ),
               ),
             ),
           ),
         ),
       );
     }
     
     // Light mode delete button
     return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFDC2626), // red-600
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFDC2626).withOpacity(0.5),
        disabledForegroundColor: Colors.white.withOpacity(0.8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minimumSize: Size.zero, 
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    final bgColor = isDark 
        ? Colors.white.withOpacity(0.05) 
        : const Color(0x1AEF4444); // red-500/10 wait implementation used 0x1A or 0x33
        
    final textColor = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
    final border = isDark ? Border.all(color: Colors.white.withOpacity(0.1)) : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12), // rounded-lg
        border: border,
      ),
      child: TextButton(
        onPressed: () => _handleLogout(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'Log out',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }

  void _handleLogout(BuildContext context) {
    context.read<AuthService>().logout();
     Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
