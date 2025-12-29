import 'package:equatable/equatable.dart';

/// File Item Entity - Based on DACN storage/entity/File.java
class FileItem extends Equatable {
  final String id;
  final String filename;
  final String originalFilename;
  final String? filePath;
  final int fileSize;
  final String mimeType;
  final String? folderId;
  final String ownerId;
  final String? ownerName;
  final int version;
  final bool isPublic;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FileItem({
    required this.id,
    required this.filename,
    required this.originalFilename,
    this.filePath,
    required this.fileSize,
    required this.mimeType,
    this.folderId,
    required this.ownerId,
    this.ownerName,
    this.version = 1,
    this.isPublic = false,
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// File extension
  String get extension {
    if (originalFilename.contains('.')) {
      return originalFilename.substring(originalFilename.lastIndexOf('.') + 1).toLowerCase();
    }
    return '';
  }

  /// Formatted file size (B, KB, MB, GB)
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Is image file
  bool get isImage => mimeType.startsWith('image/');

  /// Is video file
  bool get isVideo => mimeType.startsWith('video/');

  /// Is document file (PDF, Word, Excel)
  bool get isDocument =>
      mimeType.contains('pdf') ||
      mimeType.contains('word') ||
      mimeType.contains('excel') ||
      mimeType.contains('spreadsheet') ||
      mimeType.contains('document');

  /// Is audio file
  bool get isAudio => mimeType.startsWith('audio/');

  FileItem copyWith({
    String? id,
    String? filename,
    String? originalFilename,
    String? filePath,
    int? fileSize,
    String? mimeType,
    String? folderId,
    String? ownerId,
    String? ownerName,
    int? version,
    bool? isPublic,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FileItem(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      originalFilename: originalFilename ?? this.originalFilename,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      folderId: folderId ?? this.folderId,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      version: version ?? this.version,
      isPublic: isPublic ?? this.isPublic,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, filename, originalFilename, filePath, fileSize, mimeType,
    folderId, ownerId, ownerName, version, isPublic, isDeleted, createdAt, updatedAt
  ];
}

/// Folder Entity
class Folder extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final String ownerId;
  final DateTime createdAt;
  final int fileCount;

  const Folder({
    required this.id,
    required this.name,
    this.parentId,
    required this.ownerId,
    required this.createdAt,
    this.fileCount = 0,
  });

  @override
  List<Object?> get props => [id, name, parentId, ownerId, createdAt, fileCount];
}
