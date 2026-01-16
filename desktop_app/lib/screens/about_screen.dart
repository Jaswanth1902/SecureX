import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _productName = 'SafeCopy Owner Client';
  static const String _productSubtitle = 'SecurePrint Desktop';

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDarkMode;

    final textColor = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final mutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6);
    final cardBorder = isDark ? Border.all(color: Colors.white.withOpacity(0.1)) : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E0A30).withOpacity(0.85) : Colors.transparent,
        elevation: 0,
        title: Text(
          'About',
          style: TextStyle(
            color: textColor,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 22,
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
                : [
                    themeService.colors.backgroundGradientStart,
                    const Color(0xFFE6E6FA),
                    themeService.colors.backgroundGradientEnd,
                  ],
            stops: isDark ? null : [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              final version = info != null ? '${info.version}+${info.buildNumber}' : '1.0.0+1';
              final appName = info?.appName.isNotEmpty == true ? info!.appName : _productName;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  _buildHeader(appName, version, textColor, mutedColor),
                  const SizedBox(height: 24),
                  _buildCard(
                    cardColor,
                    border: cardBorder,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('PRODUCT', mutedColor),
                        _buildInfoRow('Name', _productName, textColor, mutedColor),
                        _buildInfoRow('Edition', _productSubtitle, textColor, mutedColor),
                        _buildInfoRow('Version', version, textColor, mutedColor),
                        _buildInfoRow('Platform', _platformLabel(), textColor, mutedColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    cardColor,
                    border: cardBorder,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('SUPPORT', mutedColor),
                        _buildTextRow(
                          'Contact',
                          'For help, contact your system administrator or support team.',
                          textColor,
                          mutedColor,
                        ),
                        _buildTextRow(
                          'Documentation',
                          'Refer to your internal deployment guide for setup and policies.',
                          textColor,
                          mutedColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    cardColor,
                    border: cardBorder,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('LEGAL', mutedColor),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text('Open-source licenses', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                          subtitle: Text('View third-party license details', style: TextStyle(color: mutedColor)),
                          trailing: Icon(Icons.open_in_new, color: mutedColor, size: 18),
                          onTap: () {
                            showLicensePage(
                              context: context,
                              applicationName: appName,
                              applicationVersion: version,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String version, Color textColor, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: textColor,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Version $version',
          style: TextStyle(color: mutedColor, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: mutedColor, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Color bgColor, {BoxBorder? border, required Widget child}) {
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
      child: child,
    );
  }

  static String _platformLabel() {
    if (Platform.isWindows) return 'Windows Desktop';
    if (Platform.isMacOS) return 'macOS Desktop';
    if (Platform.isLinux) return 'Linux Desktop';
    return 'Desktop';
  }

  Widget _buildTextRow(
    String label,
    String value,
    Color textColor,
    Color mutedColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: mutedColor, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
