class FileItem {
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedAt;
  final bool isPrinted;
  final String? printedAt;
  final String status;

  FileItem({
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.isPrinted,
    this.printedAt,
    required this.status,
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
    );
  }
}
