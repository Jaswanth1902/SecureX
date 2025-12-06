class HistoryItem {
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedAt;
  final String? deletedAt;
  final String status;
  final String statusUpdatedAt;
  final String? rejectionReason;
  final bool isPrinted;

  HistoryItem({
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    this.deletedAt,
    required this.status,
    required this.statusUpdatedAt,
    this.rejectionReason,
    required this.isPrinted,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      fileId: json['file_id'],
      fileName: json['file_name'],
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at'] ?? '',
      deletedAt: json['deleted_at'],
      status: json['status'] ?? 'UNKNOWN',
      statusUpdatedAt: json['status_updated_at'] ?? '',
      rejectionReason: json['rejection_reason'],
      isPrinted: json['is_printed'] ?? false,
    );
  }
}
