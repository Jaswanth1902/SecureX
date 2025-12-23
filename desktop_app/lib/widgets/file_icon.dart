import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class FileIcon extends StatelessWidget {
  final String fileName;
  final double size;
  final Color? color;

  const FileIcon({
    super.key,
    required this.fileName,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final extension = path.extension(fileName).toLowerCase();

    IconData iconData;
    Color iconColor;

    switch (extension) {
      case '.pdf':
        iconData = Icons.picture_as_pdf_outlined;
        iconColor = Colors.red.shade400;
        break;
      case '.doc':
      case '.docx':
      case '.txt':
      case '.rtf':
        iconData = Icons.description_outlined;
        iconColor = Colors.blue.shade400;
        break;
      case '.xls':
      case '.xlsx':
      case '.csv':
        iconData = Icons.table_chart_outlined;
        iconColor = Colors.green.shade400;
        break;
      case '.ppt':
      case '.pptx':
        iconData = Icons.slideshow_outlined; // Or present_to_all
        iconColor = Colors.orange.shade400;
        break;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
        iconData = Icons.image_outlined;
        iconColor = Colors.purple.shade400;
        break;
      case '.zip':
      case '.rar':
      case '.7z':
        iconData = Icons.folder_zip_outlined;
        iconColor = Colors.amber.shade600;
        break;
      default:
        iconData = Icons.insert_drive_file_outlined;
        iconColor = Colors.grey.shade400;
    }

    // If a specific override color is provided, use it. Otherwise use the type color.
    return Icon(
      iconData,
      size: size,
      color: color ?? iconColor,
    );
  }
}
