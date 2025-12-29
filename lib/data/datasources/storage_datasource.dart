import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../domain/entities/file_item.dart';

/// Storage Data Source Interface
abstract class StorageDataSource {
  Future<List<Folder>> getFolders({String? parentId, required String userId});
  Future<List<FileItem>> getFiles({String? folderId, required String userId});
  Future<Folder> createFolder({required String name, String? parentId, required String userId});
  Future<void> deleteFolder(String folderId);
  Future<void> renameFolder(String folderId, String newName);
  Future<FileItem> uploadFile({
    File? file,
    Uint8List? bytes,
    required String fileName,
    String? folderId,
    required String userId,
    void Function(double)? onProgress,
  });
  Future<void> deleteFile(String fileId);
  Future<void> renameFile(String fileId, String newName);
  Future<String> getDownloadUrl(String fileId);
  Future<StorageStats> getStorageStats(String userId);
}

/// Storage Statistics
class StorageStats {
  final int usedBytes;
  final int totalBytes;
  final int fileCount;
  final int folderCount;

  const StorageStats({
    required this.usedBytes,
    required this.totalBytes,
    required this.fileCount,
    required this.folderCount,
  });

  double get usedPercent => totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0;
  
  String get usedFormatted => _formatBytes(usedBytes);
  String get totalFormatted => _formatBytes(totalBytes);
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Storage Data Source Implementation using Firebase
class StorageDataSourceImpl implements StorageDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  StorageDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  CollectionReference<Map<String, dynamic>> get _foldersCollection =>
      firestore.collection('folders');

  CollectionReference<Map<String, dynamic>> get _filesCollection =>
      firestore.collection('files');

  @override
  Future<List<Folder>> getFolders({String? parentId, required String userId}) async {
    Query<Map<String, dynamic>> query = _foldersCollection
        .where('ownerId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false);

    if (parentId != null) {
      query = query.where('parentId', isEqualTo: parentId);
    } else {
      query = query.where('parentId', isNull: true);
    }

    // Remove orderBy to avoid composite index requirement
    // final snapshot = await query.orderBy('name').get();
    final snapshot = await query.get();
    
    final folders = <Folder>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      // Optimization: Removed per-folder file count query to fix loading speed.
      // Ideally this should be a denormalized field 'fileCount' on the folder document.
      
      folders.add(Folder(
        id: doc.id,
        name: data['name'] ?? '',
        parentId: data['parentId'],
        ownerId: data['ownerId'] ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        fileCount: data['fileCount'] ?? 0, // Use stored count if exists, else 0
      ));
    }

    // Sort in memory
    folders.sort((a, b) => a.name.compareTo(b.name));
    
    return folders;
  }

  @override
  Future<List<FileItem>> getFiles({String? folderId, required String userId}) async {
    Query<Map<String, dynamic>> query = _filesCollection
        .where('ownerId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false);

    if (folderId != null) {
      query = query.where('folderId', isEqualTo: folderId);
    } else {
      query = query.where('folderId', isNull: true);
    }

    // Remove orderBy to avoid composite index requirement
    // final snapshot = await query.orderBy('createdAt', descending: true).get();
    final snapshot = await query.get();
    
    final files = snapshot.docs.map((doc) {
      final data = doc.data();
      return FileItem(
        id: doc.id,
        filename: data['filename'] ?? '',
        originalFilename: data['originalFilename'] ?? data['filename'] ?? '',
        filePath: data['filePath'],
        fileSize: data['fileSize'] ?? 0,
        mimeType: data['mimeType'] ?? 'application/octet-stream',
        folderId: data['folderId'],
        ownerId: data['ownerId'] ?? '',
        ownerName: data['ownerName'],
        version: data['version'] ?? 1,
        isPublic: data['isPublic'] ?? false,
        isDeleted: data['isDeleted'] ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );
    }).toList();

    // Sort in memory
    files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return files;
  }

  @override
  Future<Folder> createFolder({
    required String name,
    String? parentId,
    required String userId,
  }) async {
    final docRef = await _foldersCollection.add({
      'name': name,
      'parentId': parentId,
      'ownerId': userId,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return Folder(
      id: docRef.id,
      name: name,
      parentId: parentId,
      ownerId: userId,
      createdAt: DateTime.now(),
      fileCount: 0,
    );
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    // Soft delete
    await _foldersCollection.doc(folderId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
    
    // Also soft delete files in folder
    final filesInFolder = await _filesCollection
        .where('folderId', isEqualTo: folderId)
        .get();
    
    for (final doc in filesInFolder.docs) {
      await doc.reference.update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> renameFolder(String folderId, String newName) async {
    await _foldersCollection.doc(folderId).update({
      'name': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<FileItem> uploadFile({
    File? file,
    Uint8List? bytes,
    required String fileName,
    String? folderId,
    required String userId,
    void Function(double)? onProgress,
  }) async {
    final storagePath = 'users/$userId/files/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    // Upload to Firebase Storage
    final ref = storage.ref().child(storagePath);
    UploadTask uploadTask;
    
    if (bytes != null) {
      uploadTask = ref.putData(bytes);
    } else if (file != null) {
      uploadTask = ref.putFile(file);
    } else {
      throw Exception('Either file or bytes must be provided');
    }
    
    // Track progress
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        onProgress(progress);
      });
    }
    
    await uploadTask;
    
    // Get file metadata
    final metadata = await ref.getMetadata();
    final downloadUrl = await ref.getDownloadURL();
    
    // Save to Firestore
    final docRef = await _filesCollection.add({
      'filename': storagePath.split('/').last,
      'originalFilename': fileName,
      'filePath': storagePath,
      'downloadUrl': downloadUrl,
      'fileSize': metadata.size ?? (bytes?.length ?? file?.lengthSync() ?? 0),
      'mimeType': metadata.contentType ?? _getMimeType(fileName),
      'folderId': folderId,
      'ownerId': userId,
      'version': 1,
      'isPublic': false,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return FileItem(
      id: docRef.id,
      filename: storagePath.split('/').last,
      originalFilename: fileName,
      filePath: storagePath,
      fileSize: metadata.size ?? (bytes?.length ?? file?.lengthSync() ?? 0),
      mimeType: metadata.contentType ?? _getMimeType(fileName),
      folderId: folderId,
      ownerId: userId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFile(String fileId) async {
    final doc = await _filesCollection.doc(fileId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final filePath = data['filePath'] as String?;
      
      // Delete from Storage
      if (filePath != null) {
        try {
          await storage.ref().child(filePath).delete();
        } catch (_) {
          // File might not exist in storage
        }
      }
      
      // Soft delete in Firestore
      await _filesCollection.doc(fileId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> renameFile(String fileId, String newName) async {
    await _filesCollection.doc(fileId).update({
      'originalFilename': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String> getDownloadUrl(String fileId) async {
    final doc = await _filesCollection.doc(fileId).get();
    if (doc.exists) {
      final data = doc.data()!;
      // Return cached URL if exists
      if (data['downloadUrl'] != null) {
        return data['downloadUrl'] as String;
      }
      // Generate new URL
      final filePath = data['filePath'] as String?;
      if (filePath != null) {
        return await storage.ref().child(filePath).getDownloadURL();
      }
    }
    throw Exception('File not found');
  }

  @override
  Future<StorageStats> getStorageStats(String userId) async {
    // Count folders
    final folderCount = await _foldersCollection
        .where('ownerId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .count()
        .get();
    
    // Get files and sum sizes
    final filesSnapshot = await _filesCollection
        .where('ownerId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .get();
    
    int totalSize = 0;
    for (final doc in filesSnapshot.docs) {
      totalSize += (doc.data()['fileSize'] as num?)?.toInt() ?? 0;
    }
    
    return StorageStats(
      usedBytes: totalSize,
      totalBytes: 5 * 1024 * 1024 * 1024, // 5GB default quota
      fileCount: filesSnapshot.docs.length,
      folderCount: folderCount.count ?? 0,
    );
  }

  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt': return 'application/vnd.ms-powerpoint';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'mp4': return 'video/mp4';
      case 'mp3': return 'audio/mpeg';
      case 'txt': return 'text/plain';
      case 'zip': return 'application/zip';
      default: return 'application/octet-stream';
    }
  }
}
