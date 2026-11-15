import '../../core/utils/date_format.dart';

/// Fotografija ili dokument pridružen računu.
class Attachment {
  const Attachment({
    required this.id,
    required this.expenseId,
    required this.mimeType,
    required this.createdAt,
    this.localPath,
    this.remotePath,
    this.sizeBytes,
  });

  factory Attachment.fromRow(Map<String, Object?> r) => Attachment(
    id: r['id']! as String,
    expenseId: r['expense_id']! as String,
    localPath: r['local_path'] as String?,
    remotePath: r['remote_path'] as String?,
    mimeType: r['mime_type']! as String,
    sizeBytes: (r['size_bytes'] as num?)?.toInt(),
    createdAt: fromDbTimestamp(r['created_at']! as String),
  );

  final String id;
  final String expenseId;
  final String? localPath;
  final String? remotePath;
  final String mimeType;
  final int? sizeBytes;
  final DateTime createdAt;

  bool get isImage => mimeType.startsWith('image/');
}

/// Datoteka koja je već kopirana u trajnu pohranu aplikacije i čeka da se
/// zapiše u bazu uz račun.
class StoredFile {
  const StoredFile({
    required this.path,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String path;
  final String mimeType;
  final int sizeBytes;
}
