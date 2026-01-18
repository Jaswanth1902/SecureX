class FileItem {
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedAt;
  final bool isPrinted;
  final String? printedAt;
  final String status;
  final String? senderPhone;

  FileItem({
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.isPrinted,
    this.printedAt,
    required this.status,
    this.senderPhone,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      fileId: json['file_id'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at'] ?? '',
      isPrinted: (json['is_printed'] == 1 || json['is_printed'] == true),
      printedAt: json['printed_at'],
      status: json['status'] ?? 'UNKNOWN',
      senderPhone: json['sender_phone'],
    );
  }

  DateTime get uploadedAtDateTime {
    try {
      var dateStr = uploadedAt;
      if (!dateStr.endsWith('Z')) {
        dateStr += 'Z';
      }
      return DateTime.parse(dateStr).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }
}
