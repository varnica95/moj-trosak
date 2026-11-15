import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/attachment.dart';
import '../utils/ids.dart';

/// Trajna pohrana fotografija i dokumenata računa u privatnoj mapi
/// aplikacije (nije vidljiva drugim aplikacijama).
class AttachmentStorage {
  AttachmentStorage({Future<Directory> Function()? baseDirectory})
    : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _baseDirectory;

  static const String _folder = 'attachments';

  Future<Directory> _dir() async {
    final base = await _baseDirectory();
    final dir = Directory(p.join(base.path, _folder));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Kopira privremenu datoteku (npr. s kamere) u trajnu pohranu.
  Future<StoredFile> store(String sourcePath) async {
    final source = File(sourcePath);
    final extension = p.extension(sourcePath).toLowerCase();
    final dir = await _dir();
    final target = File(
      p.join(dir.path, '${Ids.newId()}${extension.isEmpty ? '.jpg' : extension}'),
    );
    await source.copy(target.path);
    return StoredFile(
      path: target.path,
      mimeType: mimeTypeFor(extension),
      sizeBytes: await target.length(),
    );
  }

  /// Briše sve pohranjene datoteke (koristi se kod brisanja svih podataka).
  Future<void> deleteAll() async {
    final dir = await _dir();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  static String mimeTypeFor(String extension) => switch (extension) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.heic' => 'image/heic',
    '.pdf' => 'application/pdf',
    _ => 'image/jpeg',
  };
}
