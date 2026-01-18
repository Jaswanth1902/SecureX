import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDarkMode;

    final textColor = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final labelColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade500;
    final sectionTitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    
    // Card styles matching SettingsScreen
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5);
    final cardBorder = isDark ? Border.all(color: Colors.white.withOpacity(0.1)) : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? const Color(0xFF2D1B4E) : Colors.white,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
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
                : [themeService.colors.backgroundGradientStart, const Color(0xFFE6E6FA), themeService.colors.backgroundGradientEnd],
            stops: isDark ? null : [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'desktop_app',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0+1',
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // PRODUCT SECTION
              _buildSectionTitle('PRODUCT', sectionTitleColor),
              _buildCard(
                cardColor,
                border: cardBorder,
                children: [
                   _buildInfoRow('Name', 'SafeCopy Owner Client', textColor, isDark),
                   _buildDivider(isDark),
                   _buildInfoRow('Edition', 'SecurePrint Desktop', textColor, isDark),
                   _buildDivider(isDark),
                   _buildInfoRow('Version', '1.0.0+1', textColor, isDark),
                   _buildDivider(isDark),
                   _buildInfoRow('Platform', 'Windows Desktop', textColor, isDark),
                ],
              ),
              const SizedBox(height: 32),

              // SUPPORT SECTION
              _buildSectionTitle('SUPPORT', sectionTitleColor),
              _buildCard(
                cardColor,
                border: cardBorder,
                children: [
                  _buildDetailRow(
                    'Contact', 
                    'For help, contact your system administrator or support team.', 
                    textColor, 
                    labelColor
                  ),
                  _buildDivider(isDark),
                  _buildDetailRow(
                    'Documentation', 
                    'Refer to your internal deployment guide for setup and policies.', 
                    textColor, 
                    labelColor
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers Duplicated from SettingsScreen for visual consistency ---

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
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
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, // Label color
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
               color: textColor,
               fontWeight: FontWeight.w600,
               fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
               color: textColor,
               fontWeight: FontWeight.w500,
               fontSize: 14,
               height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
    );
  }
}
