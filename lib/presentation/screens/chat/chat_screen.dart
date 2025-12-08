/// Chat Screen
/// 
/// List of chat rooms.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tin nhắn',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, size: 26.w),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildChatItem(
            'Phòng chat ${index + 1}',
            'Tin nhắn mới nhất...',
            '${9 + index}:${30 - index * 2}',
            index < 3,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create new chat room
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildChatItem(String name, String lastMessage, String time, bool hasUnread) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to chat room
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14.w,
                      height: 14.w,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: hasUnread ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
