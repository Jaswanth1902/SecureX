import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final VoidCallback? onEditProfile;

  const ProfileCard({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8A2BE2), // BlueViolet
            Color(0xFFBA55D3), // MediumOrchid
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A2BE2).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern (optional decorative circles)
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          
          // Main content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar and logout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Text(
                          userName.isNotEmpty 
                              ? userName[0].toUpperCase() 
                              : 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8A2BE2),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    
                    // Logout button
                    IconButton(
                      onPressed: onLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // User name
                Text(
                  userName.isEmpty ? 'User' : userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // User email
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        userEmail.isEmpty ? 'email@example.com' : userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Stats row (Zomato-style)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(Icons.upload_file, '0', 'Uploads'),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white30,
                      ),
                      _buildStatItem(Icons.print_outlined, '0', 'Prints'),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white30,
                      ),
                      _buildStatItem(Icons.check_circle_outline, '0', 'Completed'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Edit profile button
                if (onEditProfile != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onEditProfile,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
