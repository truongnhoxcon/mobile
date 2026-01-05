import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/file_item.dart';
import '../../../data/datasources/storage_datasource.dart';
import '../auth/auth_bloc.dart';
import 'files_event.dart';
import 'files_state.dart';

/// Files BLoC - Enhanced with API integration
class FilesBloc extends Bloc<FilesEvent, FilesState> {
  final StorageDataSource dataSource;
  final AuthBloc authBloc;

  FilesBloc({
    required this.dataSource,
    required this.authBloc,
  }) : super(const FilesState()) {
    on<FilesLoadFolder>(_onLoadFolder);
    on<FilesUploadFile>(_onUploadFile);
    on<FilesDeleteFile>(_onDeleteFile);
    on<FilesDeleteFolder>(_onDeleteFolder);
    on<FilesCreateFolder>(_onCreateFolder);
    on<FilesRenameFile>(_onRenameFile);
    on<FilesRenameFolder>(_onRenameFolder);
    on<FilesNavigateBack>(_onNavigateBack);
    on<FilesSearch>(_onSearch);
    on<FilesSort>(_onSort);
    on<FilesToggleViewMode>(_onToggleViewMode);
  }

  String get _currentUserId => authBloc.state.user?.id ?? '';

  Future<void> _onLoadFolder(
    FilesLoadFolder event,
    Emitter<FilesState> emit,
  ) async {
    emit(state.copyWith(status: FilesBlocStatus.loading));

    try {
      final folders = await dataSource.getFolders(
        parentId: event.folderId,
        userId: _currentUserId,
      );
      
      final files = await dataSource.getFiles(
        folderId: event.folderId,
        userId: _currentUserId,
      );
      
      final stats = await dataSource.getStorageStats(_currentUserId);
      
      // Update breadcrumbs
      List<Folder> newBreadcrumbs = [...state.breadcrumbs];
      if (event.folderId == null) {
        newBreadcrumbs = [];
      } else if (event.folderId != state.currentFolderId) {
        // Find folder in current list to add to breadcrumbs
        final folder = state.folders.where((f) => f.id == event.folderId).firstOrNull;
        if (folder != null) {
          newBreadcrumbs.add(folder);
        }
      }

      // Apply sorting
      final sortedFiles = _sortFiles(files, state.sortBy, state.sortAscending);
      final sortedFolders = _sortFolders(folders, state.sortAscending);

      emit(state.copyWith(
        status: FilesBlocStatus.loaded,
        folders: sortedFolders,
        filteredFolders: sortedFolders,
        files: sortedFiles,
        filteredFiles: sortedFiles,
        currentFolderId: event.folderId,
        breadcrumbs: newBreadcrumbs,
        stats: stats,
        searchQuery: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FilesBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUploadFile(
    FilesUploadFile event,
    Emitter<FilesState> emit,
  ) async {
    // Check if user is logged in
    if (_currentUserId.isEmpty) {
      emit(state.copyWith(
        status: FilesBlocStatus.error,
        errorMessage: 'Bạn cần đăng nhập để upload file',
      ));
      return;
    }

    emit(state.copyWith(status: FilesBlocStatus.uploading, uploadProgress: 0));

    try {
      final newFile = await dataSource.uploadFile(
        file: event.file,
        bytes: event.bytes,
        fileName: event.fileName,
        folderId: event.folderId ?? state.currentFolderId,
        userId: _currentUserId,
        onProgress: (progress) {
          emit(state.copyWith(uploadProgress: progress));
        },
      );

      final updatedFiles = [newFile, ...state.files];
      final stats = await dataSource.getStorageStats(_currentUserId);

      emit(state.copyWith(
        status: FilesBlocStatus.loaded,
        files: updatedFiles,
        filteredFiles: _filterAndSortFiles(updatedFiles, state.searchQuery, state.sortBy, state.sortAscending),
        stats: stats,
        uploadProgress: 1.0,
      ));
    } catch (e, stackTrace) {
      print('Upload error: $e');
      print('Stack trace: $stackTrace');
      emit(state.copyWith(
        status: FilesBlocStatus.error,
        errorMessage: 'Upload thất bại: ${e.toString()}',
      ));
    }
  }


  Future<void> _onDeleteFile(
    FilesDeleteFile event,
    Emitter<FilesState> emit,
  ) async {
    try {
      await dataSource.deleteFile(event.fileId);
      
      final updatedFiles = state.files.where((f) => f.id != event.fileId).toList();
      final stats = await dataSource.getStorageStats(_currentUserId);

      emit(state.copyWith(
        files: updatedFiles,
        filteredFiles: state.filteredFiles.where((f) => f.id != event.fileId).toList(),
        stats: stats,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FilesBlocStatus.error,
        errorMessage: 'Xóa file thất bại: $e',
      ));
    }
  }

  Future<void> _onDeleteFolder(
    FilesDeleteFolder event,
    Emitter<FilesState> emit,
  ) async {
    try {
      await dataSource.deleteFolder(event.folderId);
      
      final updatedFolders = state.folders.where((f) => f.id != event.folderId).toList();
      
      emit(state.copyWith(
        folders: updatedFolders,
        filteredFolders: state.filteredFolders.where((f) => f.id != event.folderId).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FilesBlocStatus.error,
        errorMessage: 'Xóa thư mục thất bại: $e',
      ));
    }
  }

  Future<void> _onCreateFolder(
    FilesCreateFolder event,
    Emitter<FilesState> emit,
  ) async {
    try {
      final newFolder = await dataSource.createFolder(
        name: event.name,
        parentId: event.parentId ?? state.currentFolderId,
        userId: _currentUserId,
      );

      final updatedFolders = [...state.folders, newFolder];
      final sortedFolders = _sortFolders(updatedFolders, state.sortAscending);

      emit(state.copyWith(
        folders: sortedFolders,
        filteredFolders: _filterFolders(sortedFolders, state.searchQuery),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FilesBlocStatus.error,
        errorMessage: 'Tạo thư mục thất bại: $e',
      ));
    }
  }

  Future<void> _onRenameFile(
    FilesRenameFile event,
    Emitter<FilesState> emit,
  ) async {
    try {
      await dataSource.renameFile(event.fileId, event.newName);
      
      final updatedFiles = state.files.map((f) {
        if (f.id == event.fileId) {
          return f.copyWith(originalFilename: event.newName);
        }
        return f;
      }).toList();

      emit(state.copyWith(
        files: updatedFiles,
        filteredFiles: _filterAndSortFiles(updatedFiles, state.searchQuery, state.sortBy, state.sortAscending),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FilesBlocStatus.error,
        errorMessage: 'Đổi tên thất bại: $e',
      ));
    }
  }

  Future<void> _onRenameFolder(
    FilesRenameFolder event,
    Emitter<FilesState> emit,
  ) async {
    try {
      await dataSource.renameFolder(event.folderId, event.newName);
      
      final updatedFolders = state.folders.map((f) {
        if (f.id == event.folderId) {
          return Folder(
            id: f.id,
            name: event.newName,
            parentId: f.parentId,
            ownerId: f.ownerId,
            createdAt: f.createdAt,
            fileCount: f.fileCount,
          );
        }
        return f;
      }).toList();

      emit(state.copyWith(
        folders: updatedFolders,
        filteredFolders: _filterFolders(updatedFolders, state.searchQuery),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FilesBlocStatus.error,
        errorMessage: 'Đổi tên thất bại: $e',
      ));
    }
  }

  void _onNavigateBack(
    FilesNavigateBack event,
    Emitter<FilesState> emit,
  ) {
    if (state.breadcrumbs.isEmpty) {
      add(const FilesLoadFolder());
    } else {
      final newBreadcrumbs = List<Folder>.from(state.breadcrumbs);
      newBreadcrumbs.removeLast();
      
      final parentId = newBreadcrumbs.isEmpty ? null : newBreadcrumbs.last.id;
      
      emit(state.copyWith(breadcrumbs: newBreadcrumbs));
      add(FilesLoadFolder(folderId: parentId));
    }
  }

  void _onSearch(
    FilesSearch event,
    Emitter<FilesState> emit,
  ) {
    final query = event.query.toLowerCase();
    
    final filteredFiles = _filterAndSortFiles(state.files, query, state.sortBy, state.sortAscending);
    final filteredFolders = _filterFolders(state.folders, query);

    emit(state.copyWith(
      searchQuery: event.query,
      filteredFiles: filteredFiles,
      filteredFolders: filteredFolders,
    ));
  }

  void _onSort(
    FilesSort event,
    Emitter<FilesState> emit,
  ) {
    final sortedFiles = _sortFiles(state.files, event.sortBy, event.ascending);
    final sortedFolders = _sortFolders(state.folders, event.ascending);

    emit(state.copyWith(
      sortBy: event.sortBy,
      sortAscending: event.ascending,
      files: sortedFiles,
      filteredFiles: _filterFiles(sortedFiles, state.searchQuery),
      folders: sortedFolders,
      filteredFolders: _filterFolders(sortedFolders, state.searchQuery),
    ));
  }

  void _onToggleViewMode(
    FilesToggleViewMode event,
    Emitter<FilesState> emit,
  ) {
    emit(state.copyWith(
      viewMode: state.viewMode == FilesViewMode.list 
        ? FilesViewMode.grid 
        : FilesViewMode.list,
    ));
  }

  // Helper methods
  List<FileItem> _sortFiles(List<FileItem> files, FilesSortBy sortBy, bool ascending) {
    final sorted = List<FileItem>.from(files);
    sorted.sort((a, b) {
      int result;
      switch (sortBy) {
        case FilesSortBy.name:
          result = a.originalFilename.compareTo(b.originalFilename);
        case FilesSortBy.date:
          result = a.createdAt.compareTo(b.createdAt);
        case FilesSortBy.size:
          result = a.fileSize.compareTo(b.fileSize);
        case FilesSortBy.type:
          result = a.extension.compareTo(b.extension);
      }
      return ascending ? result : -result;
    });
    return sorted;
  }

  List<Folder> _sortFolders(List<Folder> folders, bool ascending) {
    final sorted = List<Folder>.from(folders);
    sorted.sort((a, b) {
      final result = a.name.compareTo(b.name);
      return ascending ? result : -result;
    });
    return sorted;
  }

  List<FileItem> _filterFiles(List<FileItem> files, String query) {
    if (query.isEmpty) return files;
    return files.where((f) => 
      f.originalFilename.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<Folder> _filterFolders(List<Folder> folders, String query) {
    if (query.isEmpty) return folders;
    return folders.where((f) => 
      f.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<FileItem> _filterAndSortFiles(List<FileItem> files, String query, FilesSortBy sortBy, bool ascending) {
    final filtered = _filterFiles(files, query);
    return _sortFiles(filtered, sortBy, ascending);
  }
}
