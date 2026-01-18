import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/theme_service.dart';
import 'file_icon.dart';

class FileCard extends StatefulWidget {
  final FileItem file;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const FileCard({
    super.key,
    required this.file,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  bool _isHovered = false;
  bool _isRejectHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final colors = themeService.colors;

    String timeAgo = 'Uploaded recently';
    try {
      final dt = widget.file.uploadedAtDateTime;
      final diff = DateTime.now().difference(dt);
      
      if (diff.inHours < 1) {
        if (diff.inMinutes < 1) {
          timeAgo = 'Just now';
        } else {
          timeAgo = 'Uploaded ${diff.inMinutes}m ago';
        }
      } else if (diff.inHours < 24) {
        timeAgo = 'Uploaded ${diff.inHours}h ago';
      } else {
        timeAgo = 'Uploaded ${dt.day}/${dt.month}';
      }
    } catch (_) {}

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transformAlignment: Alignment.center, // Scale from center
        margin: const EdgeInsets.only(bottom: 12),
        transform: _isHovered
            ? (Matrix4.identity()..scale(1.035))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.cardBorder),

        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon
              // Removed background decoration as requested
              FileIcon(
                fileName: widget.file.fileName,
                size: 32,
              ),
              const SizedBox(width: 16),

              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.file.fileName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(widget.file.fileSizeBytes / 1024).toStringAsFixed(1)} KB • $timeAgo${widget.file.senderPhone != null ? " • ${widget.file.senderPhone}" : ""}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reject Button
                  MouseRegion(
                    onEnter: (_) => setState(() => _isRejectHovered = true),
                    onExit: (_) => setState(() => _isRejectHovered = false),
                    child: InkWell(
                      onTap: widget.onReject,
                      borderRadius: BorderRadius.circular(50),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isRejectHovered 
                              ? colors.rejectButtonBg 
                              : Colors.transparent, // Visible only on hover
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: colors.rejectIcon,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Accept Button
                  InkWell(
                    onTap: widget.onAccept,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.acceptGradientStart,
                            colors.acceptGradientEnd
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colors.acceptGradientStart.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.print, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Print',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
