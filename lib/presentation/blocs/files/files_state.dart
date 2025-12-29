import 'package:equatable/equatable.dart';
import '../../../domain/entities/file_item.dart';
import '../../../data/datasources/storage_datasource.dart';
import 'files_event.dart';

/// Files Bloc Status
enum FilesBlocStatus {
  initial,
  loading,
  loaded,
  uploading,
  error,
}

/// View mode
enum FilesViewMode {
  list,
  grid,
}

/// Files State - Enhanced
class FilesState extends Equatable {
  final FilesBlocStatus status;
  final List<FileItem> files;
  final List<FileItem> filteredFiles;
  final List<Folder> folders;
  final List<Folder> filteredFolders;
  final String? currentFolderId;
  final List<Folder> breadcrumbs;
  final StorageStats? stats;
  final double uploadProgress;
  final String? errorMessage;
  final String searchQuery;
  final FilesSortBy sortBy;
  final bool sortAscending;
  final FilesViewMode viewMode;

  const FilesState({
    this.status = FilesBlocStatus.initial,
    this.files = const [],
    this.filteredFiles = const [],
    this.folders = const [],
    this.filteredFolders = const [],
    this.currentFolderId,
    this.breadcrumbs = const [],
    this.stats,
    this.uploadProgress = 0,
    this.errorMessage,
    this.searchQuery = '',
    this.sortBy = FilesSortBy.date,
    this.sortAscending = false,
    this.viewMode = FilesViewMode.list,
  });

  FilesState copyWith({
    FilesBlocStatus? status,
    List<FileItem>? files,
    List<FileItem>? filteredFiles,
    List<Folder>? folders,
    List<Folder>? filteredFolders,
    String? currentFolderId,
    List<Folder>? breadcrumbs,
    StorageStats? stats,
    double? uploadProgress,
    String? errorMessage,
    String? searchQuery,
    FilesSortBy? sortBy,
    bool? sortAscending,
    FilesViewMode? viewMode,
  }) {
    return FilesState(
      status: status ?? this.status,
      files: files ?? this.files,
      filteredFiles: filteredFiles ?? this.filteredFiles,
      folders: folders ?? this.folders,
      filteredFolders: filteredFolders ?? this.filteredFolders,
      currentFolderId: currentFolderId,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      stats: stats ?? this.stats,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  @override
  List<Object?> get props => [
    status, files, filteredFiles, folders, filteredFolders, 
    currentFolderId, breadcrumbs, stats, uploadProgress, 
    errorMessage, searchQuery, sortBy, sortAscending, viewMode
  ];
}
