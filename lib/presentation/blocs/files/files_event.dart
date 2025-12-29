import 'package:equatable/equatable.dart';
import 'dart:io';
import 'dart:typed_data';

/// Files Bloc Events - Enhanced
abstract class FilesEvent extends Equatable {
  const FilesEvent();

  @override
  List<Object?> get props => [];
}

/// Load files in folder
class FilesLoadFolder extends FilesEvent {
  final String? folderId;
  const FilesLoadFolder({this.folderId});
  
  @override
  List<Object?> get props => [folderId];
}

/// Upload file
class FilesUploadFile extends FilesEvent {
  final File? file;
  final Uint8List? bytes;
  final String fileName;
  final String? folderId;
  
  const FilesUploadFile({this.file, this.bytes, required this.fileName, this.folderId});
  
  @override
  List<Object?> get props => [file?.path, bytes?.length, fileName, folderId];
}

/// Delete file
class FilesDeleteFile extends FilesEvent {
  final String fileId;
  const FilesDeleteFile(this.fileId);
  
  @override
  List<Object?> get props => [fileId];
}

/// Delete folder
class FilesDeleteFolder extends FilesEvent {
  final String folderId;
  const FilesDeleteFolder(this.folderId);
  
  @override
  List<Object?> get props => [folderId];
}

/// Create folder
class FilesCreateFolder extends FilesEvent {
  final String name;
  final String? parentId;
  
  const FilesCreateFolder({required this.name, this.parentId});
  
  @override
  List<Object?> get props => [name, parentId];
}

/// Rename file
class FilesRenameFile extends FilesEvent {
  final String fileId;
  final String newName;
  
  const FilesRenameFile({required this.fileId, required this.newName});
  
  @override
  List<Object?> get props => [fileId, newName];
}

/// Rename folder
class FilesRenameFolder extends FilesEvent {
  final String folderId;
  final String newName;
  
  const FilesRenameFolder({required this.folderId, required this.newName});
  
  @override
  List<Object?> get props => [folderId, newName];
}

/// Navigate back to parent folder
class FilesNavigateBack extends FilesEvent {
  const FilesNavigateBack();
}

/// Search files
class FilesSearch extends FilesEvent {
  final String query;
  const FilesSearch(this.query);
  
  @override
  List<Object?> get props => [query];
}

/// Sort files
class FilesSort extends FilesEvent {
  final FilesSortBy sortBy;
  final bool ascending;
  
  const FilesSort({required this.sortBy, this.ascending = true});
  
  @override
  List<Object?> get props => [sortBy, ascending];
}

/// Toggle view mode
class FilesToggleViewMode extends FilesEvent {
  const FilesToggleViewMode();
}

/// Sort options
enum FilesSortBy {
  name,
  date,
  size,
  type,
}
