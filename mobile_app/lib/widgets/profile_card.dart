import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback? onLogout;
  final VoidCallback? onEditProfile;
  final int uploads;
  final int prints;
  final int completed;

  const ProfileCard({
    Key? key,
    required this.userName,
    required this.userEmail,
    this.onLogout,
    this.onEditProfile,
    this.uploads = 0,
    this.prints = 0,
    this.completed = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Game card coloring restored
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Use exact purple-pink gradient as in screenshots for both themes
    final cardGradient = LinearGradient(
      colors: isDark
          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] // Deep navy/black for dark theme
          : [const Color(0xFF7B2FF2), const Color(0xFFf357a8)], // Keep original colorful gradient for light theme
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final textColor = Colors.white;
    final subTextColor = Colors.white70;
    final accentColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFFf093fb);

    return Container(
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: accentColor.withOpacity(0.1),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Logout icon removed from ProfileCard as per request
              ],
            ),
            const SizedBox(height: 16),
            Text(
              userName.isEmpty ? 'User' : userName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: subTextColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    userEmail.isEmpty ? 'email@example.com' : userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: subTextColor,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.upload_file, uploads.toString(), 'Uploads', accentColor, textColor),
                  Container(
                    width: 1,
                    height: 30,
                    color: accentColor.withOpacity(0.2),
                  ),
                  _buildStatItem(Icons.print_outlined, prints.toString(), 'Prints', accentColor, textColor),
                  Container(
                    width: 1,
                    height: 30,
                    color: accentColor.withOpacity(0.2),
                  ),
                  _buildStatItem(Icons.check_circle_outline, completed.toString(), 'Completed', accentColor, textColor),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEditProfile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(Icons.edit_outlined, size: 18, color: accentColor),
                label: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: accentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color accent, Color textColor) {
    return Column(
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: accent.withOpacity(0.8),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}