import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_container.dart';
import 'notifications_screen.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import '../main.dart'; // Import for UploadPage and JobsPage wrappers if needed, or import screens directly
import 'settings_screen.dart';
import '../services/local_file_service.dart';
import '../widgets/recent_files_list.dart';
// Note: We need to import the wrappers or screens. Since they are in main.dart, we can import main.
// However, circular dependency might be annoyance. Better to move wrappers to separate files or just define logic here.
// Let's rely on importing main.dart or just defining the routes inline if possible. 
// Actually, `UploadPage` and `JobsPage` are top level in main.dart. 

class HomeScreen extends StatelessWidget {
  final VoidCallback onLogout;
  final NotificationService notificationService;
  final Function(int)? onTabSwitchRequested;
  final Function(String)? onFileSelectedForUpload;

  const HomeScreen({
    super.key,
    required this.onLogout,
    required this.notificationService,
    this.onTabSwitchRequested,
    this.onFileSelectedForUpload,
  });

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent, // Important for gradient to show
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0, // Hide default app bar, we build custom header
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Welcome to SecureX',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Secure printing made simple',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    GlassContainer(
                      padding: const EdgeInsets.all(8),
                      borderRadius: BorderRadius.circular(50),
                      onTap: () => _navigateTo(context, SettingsScreen(onLogout: onLogout)),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Main Dashboard Grid
                SizedBox(
                  height: 200, // Fixed height for the grid area
                  child: Row(
                    children: [
                      // Upload Card (Left, Large)
                      Expanded(
                        child: GlassContainer(
                          onTap: () {
                            if (onTabSwitchRequested != null) {
                              onTabSwitchRequested!(2); // Upload tab
                            } else {
                              _navigateTo(context, const UploadPage());
                            }
                          }, 
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.upload_file,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Upload',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right Column (History & Notifications)
                      Expanded(
                        child: Column(
                          children: [
                            // File History
                            Expanded(
                              child: GlassContainer(
                                onTap: () {
                                  if (onTabSwitchRequested != null) {
                                    onTabSwitchRequested!(0); // History tab
                                  } else {
                                    _navigateTo(context, const JobsPage());
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.history,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'File History',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Notifications
                            Expanded(
                              child: GlassContainer(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChangeNotifierProvider<NotificationService>.value(
                                        value: notificationService,
                                        child: const NotificationsScreen(),
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Notifications',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Recent Activity Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Documents',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (onTabSwitchRequested != null) {
                          onTabSwitchRequested!(2); // Upload tab
                        } else {
                          _navigateTo(context, const UploadPage());
                        }
                      },
                      child: const Text(
                        'Browse More',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Recent Files List
                Expanded(
                  child: SingleChildScrollView(
                    child: RecentFilesList(
                      onFileSelected: (localFile) {
                        if (onFileSelectedForUpload != null) {
                          onFileSelectedForUpload!(localFile.path);
                        } else {
                           // Fallback if callback not provided (shouldn't happen in MainLayout)
                           _navigateTo(context, UploadPage(filePath: localFile.path));
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
