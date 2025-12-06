import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class GlassDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final String confirmText;
  final bool isDestructive;

  const GlassDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmText = 'Confirm',
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDarkMode;
    final colors = themeService.colors;

    return Dialog(
      insetPadding: const EdgeInsets.all(24), // Match Dashboard padding
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), // Increased blur intensity
          child: Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity, // Full width capability
            constraints: const BoxConstraints(maxWidth: 800), // Max for very large screens
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withOpacity(0.4) 
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.white.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        onConfirm();
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive ? Colors.red.shade400 : const Color(0xFF8A2BE2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(confirmText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
