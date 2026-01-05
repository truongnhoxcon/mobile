import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/file_item.dart';
import '../../../data/datasources/storage_datasource.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../blocs/blocs.dart';

/// Files Screen - Enhanced with all features
class FilesScreen extends StatelessWidget {
  final bool isEmbedded;

  const FilesScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<FilesBloc>()..add(const FilesLoadFolder()),
      child: _FilesScreenContent(isEmbedded: isEmbedded),
    );
  }
}

class _FilesScreenContent extends StatefulWidget {
  final bool isEmbedded;
  const _FilesScreenContent({this.isEmbedded = false});

  @override
  State<_FilesScreenContent> createState() => _FilesScreenContentState();
}

class _FilesScreenContentState extends State<_FilesScreenContent> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FilesBloc, FilesState>(
      listener: (context, state) {
        if (state.status == FilesBlocStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: widget.isEmbedded ? null : _buildAppBar(context, state),
          body: _buildBody(context, state),
          floatingActionButton: _buildFAB(context, state),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, FilesState state) {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _isSearching = false);
            _searchController.clear();
            context.read<FilesBloc>().add(const FilesSearch(''));
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
          onChanged: (value) => context.read<FilesBloc>().add(FilesSearch(value)),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                context.read<FilesBloc>().add(const FilesSearch(''));
              },
            ),
        ],
      );
    }

    return AppBar(
      leading: state.currentFolderId != null
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.read<FilesBloc>().add(const FilesNavigateBack()),
          )
        : null,
      title: Text(
        state.currentFolderId != null && state.breadcrumbs.isNotEmpty
          ? state.breadcrumbs.last.name
          : 'Tài liệu',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
        _buildSortMenu(context, state),
        IconButton(
          icon: Icon(state.viewMode == FilesViewMode.list ? Icons.grid_view : Icons.list),
          onPressed: () => context.read<FilesBloc>().add(const FilesToggleViewMode()),
        ),
        IconButton(
          icon: const Icon(Icons.create_new_folder_outlined),
          onPressed: () => _showCreateFolderDialog(context),
        ),
      ],
    );
  }

  Widget _buildSortMenu(BuildContext context, FilesState state) {
    return PopupMenuButton<FilesSortBy>(
      icon: const Icon(Icons.sort),
      onSelected: (sortBy) {
        final ascending = state.sortBy == sortBy ? !state.sortAscending : true;
        context.read<FilesBloc>().add(FilesSort(sortBy: sortBy, ascending: ascending));
      },
      itemBuilder: (_) => [
        _buildSortMenuItem(FilesSortBy.name, 'Tên', state),
        _buildSortMenuItem(FilesSortBy.date, 'Ngày', state),
        _buildSortMenuItem(FilesSortBy.size, 'Kích thước', state),
        _buildSortMenuItem(FilesSortBy.type, 'Loại', state),
      ],
    );
  }

  PopupMenuItem<FilesSortBy> _buildSortMenuItem(FilesSortBy sortBy, String label, FilesState state) {
    final isSelected = state.sortBy == sortBy;
    return PopupMenuItem(
      value: sortBy,
      child: Row(
        children: [
          Text(label),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              state.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, FilesState state) {
    if (state.status == FilesBlocStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => context.read<FilesBloc>().add(
        FilesLoadFolder(folderId: state.currentFolderId)
      ),
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Storage Quota Card
          if (state.stats != null && state.currentFolderId == null)
            _buildStorageQuotaCard(state.stats!),
          
          if (state.stats != null && state.currentFolderId == null)
            SizedBox(height: 16.h),
          
          // Breadcrumbs
          if (state.breadcrumbs.isNotEmpty)
            _buildBreadcrumbs(context, state),
          
          if (state.breadcrumbs.isNotEmpty)
            SizedBox(height: 12.h),
          
          // Upload Progress
          if (state.status == FilesBlocStatus.uploading)
            _buildUploadProgress(state.uploadProgress),
          
          // Empty State
          if (state.filteredFolders.isEmpty && state.filteredFiles.isEmpty)
            _buildEmptyState(state.searchQuery.isNotEmpty),
          
          // Folders Section
          if (state.filteredFolders.isNotEmpty) ...[
            _SectionHeader(title: 'Thư mục', count: state.filteredFolders.length),
            SizedBox(height: 8.h),
            if (state.viewMode == FilesViewMode.list)
              ...state.filteredFolders.map((f) => _FolderCard(folder: f))
            else
              _buildFoldersGrid(state.filteredFolders),
            SizedBox(height: 16.h),
          ],
          
          // Files Section
          if (state.filteredFiles.isNotEmpty) ...[
            _SectionHeader(title: 'Tệp', count: state.filteredFiles.length),
            SizedBox(height: 8.h),
            if (state.viewMode == FilesViewMode.list)
              ...state.filteredFiles.map((f) => _FileCard(file: f))
            else
              _buildFilesGrid(state.filteredFiles),
          ],
        ],
      ),
    );
  }

  Widget _buildStorageQuotaCard(StorageStats stats) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: Colors.white, size: 24.w),
              SizedBox(width: 8.w),
              Text(
                'Dung lượng lưu trữ',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Text(
                stats.usedFormatted,
                style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold),
              ),
              Text(
                ' / ${stats.totalFormatted}',
                style: TextStyle(color: Colors.white70, fontSize: 16.sp),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: stats.usedPercent / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              color: stats.usedPercent > 80 ? Colors.amber : Colors.white,
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatChip(Icons.folder, '${stats.folderCount} thư mục'),
              _buildStatChip(Icons.insert_drive_file, '${stats.fileCount} tệp'),
              _buildStatChip(Icons.pie_chart, '${stats.usedPercent.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14.w),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12.sp)),
      ],
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, FilesState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          InkWell(
            onTap: () {
              // Clear breadcrumbs and go to root
              context.read<FilesBloc>().add(const FilesLoadFolder());
            },
            child: Row(
              children: [
                Icon(Icons.home, size: 18.w, color: AppColors.primary),
                SizedBox(width: 4.w),
                Text('Tài liệu', style: TextStyle(color: AppColors.primary, fontSize: 13.sp)),
              ],
            ),
          ),
          ...state.breadcrumbs.asMap().entries.map((entry) {
            final index = entry.key;
            final folder = entry.value;
            final isLast = index == state.breadcrumbs.length - 1;
            
            return Row(
              children: [
                SizedBox(width: 4.w),
                Icon(Icons.chevron_right, size: 18.w, color: AppColors.textSecondary),
                SizedBox(width: 4.w),
                InkWell(
                  onTap: isLast ? null : () {
                    // Navigate to this folder
                    context.read<FilesBloc>().add(FilesLoadFolder(folderId: folder.id));
                  },
                  child: Text(
                    folder.name,
                    style: TextStyle(
                      color: isLast ? AppColors.textPrimary : AppColors.primary,
                      fontSize: 13.sp,
                      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUploadProgress(double progress) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24.w,
            height: 24.w,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              color: AppColors.info,
            ),
          ),
          SizedBox(width: 12.w),
          Text('Đang tải lên... ${(progress * 100).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 40.h),
          Icon(
            isSearching ? Icons.search_off : Icons.folder_off_outlined,
            size: 64.w,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            isSearching ? 'Không tìm thấy kết quả' : 'Chưa có tài liệu',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersGrid(List<Folder> folders) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 1.5,
      ),
      itemCount: folders.length,
      itemBuilder: (context, index) => _FolderGridItem(folder: folders[index]),
    );
  }

  Widget _buildFilesGrid(List<FileItem> files) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 1.2,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) => _FileGridItem(file: files[index]),
    );
  }

  Widget? _buildFAB(BuildContext context, FilesState state) {
    if (state.status == FilesBlocStatus.uploading) return null;
    
    return FloatingActionButton.extended(
      onPressed: () => _handleUpload(context),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.upload_file, color: Colors.white),
      label: const Text('Upload', style: TextStyle(color: Colors.white)),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tạo thư mục mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Tên thư mục',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<FilesBloc>().add(FilesCreateFolder(name: controller.text.trim()));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpload(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true); // withData is needed for Web bytes
      
      if (result != null) {
        final platformFile = result.files.single;
        
        if (kIsWeb) {
          // Web: must use bytes, path is not available
          if (platformFile.bytes != null) {
            context.read<FilesBloc>().add(FilesUploadFile(
              bytes: platformFile.bytes,
              fileName: platformFile.name,
            ));
          }
        } else {
          // Mobile/Desktop: use file path
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            context.read<FilesBloc>().add(FilesUploadFile(
              file: file,
              fileName: platformFile.name,
            ));
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn file: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}

// ============================================================================
// Section Header
// ============================================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text('$count', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
      ],
    );
  }
}

// ============================================================================
// Folder Cards
// ============================================================================
class _FolderCard extends StatelessWidget {
  final Folder folder;

  const _FolderCard({required this.folder});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: () => context.read<FilesBloc>().add(FilesLoadFolder(folderId: folder.id)),
        onLongPress: () => _showFolderOptions(context),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCD34D).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.folder, color: const Color(0xFFF59E0B), size: 24.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(folder.name, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2.h),
                    Text('${folder.fileCount} tệp', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20.w),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
                  const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                ],
                onSelected: (value) => _handleMenuAction(context, value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFolderOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Đổi tên'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.error),
              title: Text('Xóa', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context);
      case 'delete':
        _confirmDelete(context);
    }
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đổi tên thư mục'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<FilesBloc>().add(FilesRenameFolder(folderId: folder.id, newName: controller.text.trim()));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa thư mục?'),
        content: Text('Thư mục "${folder.name}" và tất cả file bên trong sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<FilesBloc>().add(FilesDeleteFolder(folder.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _FolderGridItem extends StatelessWidget {
  final Folder folder;

  const _FolderGridItem({required this.folder});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.read<FilesBloc>().add(FilesLoadFolder(folderId: folder.id)),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder, color: const Color(0xFFF59E0B), size: 40.w),
            SizedBox(height: 8.h),
            Text(folder.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${folder.fileCount} tệp', style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// File Cards
// ============================================================================
class _FileCard extends StatefulWidget {
  final FileItem file;

  const _FileCard({required this.file});

  @override
  State<_FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<_FileCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final file = widget.file;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _isExpanded ? _getFileColor(file) : AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: _getFileColor(file).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(_getFileIcon(file), color: _getFileColor(file), size: 24.w),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(file.originalFilename, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Text(file.fileSizeFormatted, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                            SizedBox(width: 12.w),
                            Text(DateFormat('dd/MM/yyyy').format(file.createdAt), style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
              child: Column(
                children: [
                  const Divider(height: 1),
                  SizedBox(height: 12.h),
                  _buildDetailRow('Tên file', file.originalFilename),
                  _buildDetailRow('Kích thước', file.fileSizeFormatted),
                  _buildDetailRow('Loại', file.mimeType.split('/').last.toUpperCase()),
                  _buildDetailRow('Ngày tạo', DateFormat('dd/MM/yyyy HH:mm').format(file.createdAt)),
                  if (file.ownerName != null) _buildDetailRow('Chủ sở hữu', file.ownerName!),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleRename(context),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Đổi tên'),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleDelete(context),
                          icon: Icon(Icons.delete, size: 18, color: AppColors.error),
                          label: Text('Xóa', style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _handleRename(BuildContext context) {
    final controller = TextEditingController(text: widget.file.originalFilename);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đổi tên file'),
        content: TextField(controller: controller, decoration: const InputDecoration(border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<FilesBloc>().add(FilesRenameFile(fileId: widget.file.id, newName: controller.text.trim()));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _handleDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa file?'),
        content: Text('File "${widget.file.originalFilename}" sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<FilesBloc>().add(FilesDeleteFile(widget.file.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(FileItem file) {
    if (file.isImage) return Icons.image;
    if (file.isVideo) return Icons.video_file;
    if (file.isAudio) return Icons.audio_file;
    if (file.isDocument) {
      if (file.mimeType.contains('pdf')) return Icons.picture_as_pdf;
      if (file.mimeType.contains('word')) return Icons.description;
      if (file.mimeType.contains('sheet') || file.mimeType.contains('excel')) return Icons.table_chart;
    }
    return Icons.insert_drive_file;
  }

  Color _getFileColor(FileItem file) {
    if (file.isImage) return const Color(0xFF8B5CF6);
    if (file.isVideo) return const Color(0xFFEC4899);
    if (file.isAudio) return const Color(0xFF06B6D4);
    if (file.mimeType.contains('pdf')) return const Color(0xFFEF4444);
    if (file.mimeType.contains('word')) return const Color(0xFF3B82F6);
    if (file.mimeType.contains('sheet') || file.mimeType.contains('excel')) return const Color(0xFF22C55E);
    return AppColors.textSecondary;
  }
}

class _FileGridItem extends StatelessWidget {
  final FileItem file;

  const _FileGridItem({required this.file});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getFileIcon(file), color: _getFileColor(file), size: 36.w),
            SizedBox(height: 8.h),
            Text(file.originalFilename, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            SizedBox(height: 4.h),
            Text(file.fileSizeFormatted, style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(FileItem file) {
    if (file.isImage) return Icons.image;
    if (file.isVideo) return Icons.video_file;
    if (file.isAudio) return Icons.audio_file;
    if (file.mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (file.mimeType.contains('word')) return Icons.description;
    if (file.mimeType.contains('sheet') || file.mimeType.contains('excel')) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(FileItem file) {
    if (file.isImage) return const Color(0xFF8B5CF6);
    if (file.isVideo) return const Color(0xFFEC4899);
    if (file.isAudio) return const Color(0xFF06B6D4);
    if (file.mimeType.contains('pdf')) return const Color(0xFFEF4444);
    if (file.mimeType.contains('word')) return const Color(0xFF3B82F6);
    return AppColors.textSecondary;
  }
}
