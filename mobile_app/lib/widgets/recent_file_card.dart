import 'package:flutter/material.dart';
import '../services/local_file_service.dart';
import 'glass_container.dart';
import 'package:intl/intl.dart';

class RecentFileCard extends StatelessWidget {
  final LocalFile file;
  final VoidCallback onTap;

  const RecentFileCard({
    super.key,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPdf = file.extension == 'pdf';
    final String timeAgo = _formatTimeAgo(file.lastModified);
    final bool isHistoryItem = file.path.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // File Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isHistoryItem 
                    ? Colors.green 
                    : (isPdf ? Colors.red : Colors.blue)).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isHistoryItem ? Icons.history : (isPdf ? Icons.picture_as_pdf : Icons.description),
                color: isHistoryItem 
                    ? Colors.green.shade300 
                    : (isPdf ? Colors.red.shade300 : Colors.blue.shade300),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // File Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        isHistoryItem ? 'Previous Upload' : file.sizeFormatted,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Icon
            Icon(
              isHistoryItem ? Icons.cloud_upload_outlined : Icons.upload_outlined,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
