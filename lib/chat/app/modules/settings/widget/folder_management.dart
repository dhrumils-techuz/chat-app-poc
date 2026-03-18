import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../data/model/chat_folder_model.dart';
import '../../../data/repository/folder_repository.dart';

class FolderManagement extends GetView<FolderManagementController> {
  const FolderManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.surfaceColor,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: Text(
          Keys.Manage_Folders.tr,
          style: ChatTextStyles.appBarTitle.copyWith(
            color: colors.textPrimary,
          ),
        ),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: colors.primaryColor),
          );
        }

        if (controller.folders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: AppSizes.dimenToPx64,
                  color: colors.textLight,
                ),
                const SizedBox(height: AppSizes.dimenToPx16),
                Text(
                  Keys.No_folders_yet.tr,
                  style: ChatTextStyles.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.dimenToPx8),
                Text(
                  Keys.Create_folder_hint.tr,
                  style: ChatTextStyles.caption.copyWith(
                    color: colors.textLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.dimenToPx16),
          itemCount: controller.folders.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSizes.dimenToPx8),
          itemBuilder: (context, index) {
            final folder = controller.folders[index];
            return _buildFolderTile(context, folder, colors);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateFolderDialog(context),
        backgroundColor: colors.primaryColor,
        child: Icon(Icons.add, color: colors.onPrimaryColor),
      ),
    );
  }

  Widget _buildFolderTile(
    BuildContext context,
    ChatFolderModel folder,
    ChatColors colors,
  ) {
    return Dismissible(
      key: Key(folder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.dimenToPx20),
        decoration: BoxDecoration(
          color: colors.errorColor,
          borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: colors.onPrimaryColor,
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(context, folder.name, colors),
      onDismissed: (_) => controller.deleteFolder(folder.id),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.dimenToPx16,
            vertical: AppSizes.dimenToPx4,
          ),
          leading: Icon(
            Icons.folder_rounded,
            color: colors.primaryColor,
            size: AppSizes.dimenToPx32,
          ),
          title: Text(
            folder.name,
            style: ChatTextStyles.bodySemiBold.copyWith(
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            Keys.N_conversations.tr.replaceAll('@count', '${folder.conversationCount}'),
            style: ChatTextStyles.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: colors.errorColor,
            ),
            onPressed: () async {
              final confirmed =
                  await _confirmDelete(context, folder.name, colors);
              if (confirmed == true) {
                controller.deleteFolder(folder.id);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context,
    String folderName,
    ChatColors colors,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
        ),
        title: Text(
          Keys.Delete_Folder.tr,
          style: ChatTextStyles.heading.copyWith(color: colors.textPrimary),
        ),
        content: Text(
          Keys.Confirm_delete_folder.tr.replaceAll('@name', folderName),
          style: ChatTextStyles.body.copyWith(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              Keys.Cancel.tr,
              style: ChatTextStyles.bodySemiBold.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              Keys.Delete.tr,
              style: ChatTextStyles.bodySemiBold.copyWith(
                color: colors.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final colors = ChatColors.getInstance(context);
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
        ),
        title: Text(
          Keys.New_Folder.tr,
          style: ChatTextStyles.heading.copyWith(color: colors.textPrimary),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: ChatTextStyles.body.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: Keys.Folder_Name.tr,
            hintStyle: ChatTextStyles.body.copyWith(color: colors.textLight),
            filled: true,
            fillColor: colors.inputBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.dimenToPx8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.dimenToPx12,
              vertical: AppSizes.dimenToPx12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              Keys.Cancel.tr,
              style: ChatTextStyles.bodySemiBold.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                controller.createFolder(name);
                Navigator.of(context).pop();
              }
            },
            child: Text(
              Keys.Create.tr,
              style: ChatTextStyles.bodySemiBold.copyWith(
                color: colors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FolderManagementController extends GetxController {
  final FolderRepository _folderRepository;

  FolderManagementController({required FolderRepository folderRepository})
      : _folderRepository = folderRepository;

  final folders = <ChatFolderModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadFolders();
  }

  Future<void> loadFolders() async {
    try {
      isLoading.value = true;
      final response = await _folderRepository.getFolders();
      if (response.data != null) {
        final rawData = response.data;
        final List folderData = rawData is Map
            ? (rawData['data'] as List? ?? [])
            : (rawData as List);
        final list = folderData
            .map((json) =>
                ChatFolderModel.fromJson(json as Map<String, dynamic>))
            .toList();
        folders.assignAll(list);
      }
    } catch (_) {
      Get.snackbar(
        Keys.Error.tr,
        Keys.Failed_to_load_folders.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createFolder(String name) async {
    try {
      final response = await _folderRepository.createFolder(name: name);
      if (response.data != null) {
        final rawData = response.data;
        final folderJson = rawData is Map && rawData.containsKey('data')
            ? rawData['data'] as Map<String, dynamic>
            : rawData as Map<String, dynamic>;
        final folder = ChatFolderModel.fromJson(folderJson);
        folders.add(folder);
      }
    } catch (_) {
      Get.snackbar(
        Keys.Error.tr,
        Keys.Failed_to_create_folder.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteFolder(String folderId) async {
    try {
      await _folderRepository.deleteFolder(folderId);
      folders.removeWhere((f) => f.id == folderId);
    } catch (_) {
      Get.snackbar(
        Keys.Error.tr,
        Keys.Failed_to_delete_folder.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      loadFolders();
    }
  }
}
