import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/data/api_response_model.dart';
import '../../../../../core/theme/color.dart';
import '../../../../../core/theme/text_style.dart';
import '../../../../../core/utils/logs_helper.dart';
import '../../../../../core/values/app_sizes.dart';
import '../../../../data/model/user_model.dart';
import '../../../../data/repository/chat_repository.dart';
import '../../../../widgets/avatar_widget.dart';

class AddMemberDialog extends StatefulWidget {
  const AddMemberDialog({
    super.key,
    required this.chatRepository,
    required this.existingMemberIds,
    required this.onMemberSelected,
  });

  final ChatRepository chatRepository;
  final List<String> existingMemberIds;
  final void Function(UserModel) onMemberSelected;

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  static const String _tag = 'AddMemberDialog';

  final _searchController = TextEditingController();
  final _searchResults = <UserModel>[];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(query.trim());
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final ApiResponseModel response =
          await widget.chatRepository.searchUsers(query);
      if (response.isSuccessful && response.data != null) {
        final users = (response.data as List)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .where((u) => !widget.existingMemberIds.contains(u.id))
            .toList();
        setState(() => _searchResults
          ..clear()
          ..addAll(users));
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error searching users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.dimenToPx16),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 480),
        padding: const EdgeInsets.all(AppSizes.dimenToPx16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Member',
              style: ChatTextStyles.heading.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.dimenToPx16),

            // Search bar
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: ChatTextStyles.body.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: ChatTextStyles.small.copyWith(
                  color: colors.textLight,
                ),
                filled: true,
                fillColor: colors.inputBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.dimenToPx12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.dimenToPx16,
                  vertical: AppSizes.dimenToPx10,
                ),
                prefixIcon: Icon(Icons.search, color: colors.iconColor),
              ),
            ),
            const SizedBox(height: AppSizes.dimenToPx12),

            // Results
            Flexible(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colors.primaryColor,
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Search for users to add'
                                : 'No users found',
                            style: ChatTextStyles.body.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: AvatarWidget(
                                imageUrl: user.avatarUrl,
                                name: user.name,
                                size: AppSizes.avatarSmall,
                              ),
                              title: Text(
                                user.name,
                                style:
                                    ChatTextStyles.bodySemiBold.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              subtitle: user.designation != null
                                  ? Text(
                                      user.designation!,
                                      style:
                                          ChatTextStyles.small.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                widget.onMemberSelected(user);
                                Get.back();
                              },
                            );
                          },
                        ),
            ),

            const SizedBox(height: AppSizes.dimenToPx8),

            // Cancel button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Cancel',
                  style: ChatTextStyles.buttonText.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
