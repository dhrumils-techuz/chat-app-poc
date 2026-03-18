import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/extension/datetime_extensions.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../../core/values/app_strings.dart';
import '../chat_detail_controller.dart';

/// Inline header search overlay that replaces the chat content.
/// Shows a search bar at the top and card-style results below.
class MessageSearchOverlay extends StatefulWidget {
  const MessageSearchOverlay({super.key});

  @override
  State<MessageSearchOverlay> createState() => _MessageSearchOverlayState();
}

class _MessageSearchOverlayState extends State<MessageSearchOverlay> {
  final _searchController = TextEditingController();
  late final ChatDetailController _controller;
  final _hasText = false.obs;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ChatDetailController>();
    _searchController.addListener(() {
      _hasText.value = _searchController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hasText.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return SafeArea(
      child: Container(
        color: colors.backgroundColor,
        child: Column(
          children: [
            // ── Full-Width Pill Search Bar ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Obx(() => TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _controller.onSearchQueryChanged,
                style: ChatTextStyles.body.copyWith(
                  color: colors.textPrimary,
                ),
                cursorColor: colors.primaryColor,
                decoration: InputDecoration(
                  hintText: Keys.Search_messages.tr,
                  hintStyle: ChatTextStyles.body.copyWith(
                    color: colors.textLight,
                  ),
                  filled: true,
                  fillColor: colors.inputBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.dimenToPx16,
                    vertical: AppSizes.dimenToPx12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.search, color: colors.iconColor),
                  // X button: clears text if present, closes search if empty
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: _hasText.value
                          ? colors.textPrimary
                          : colors.iconColor,
                    ),
                    onPressed: () {
                      if (_searchController.text.isNotEmpty) {
                        _searchController.clear();
                        _controller.onSearchQueryChanged('');
                      } else {
                        _controller.toggleSearch();
                      }
                    },
                  ),
                ),
              )),
            ),

            // ── Results Area ──────────────────────────────────────────
            Expanded(
              child: Obx(() {
                // Loading spinner
                if (_controller.isSearchLoading.value) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colors.primaryColor,
                    ),
                  );
                }

                // Empty prompt — no query typed yet
                if (!_hasText.value) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search,
                            size: 48, color: colors.textLight),
                        const SizedBox(height: 12),
                        Text(
                          Keys.Search_messages.tr,
                          style: ChatTextStyles.body.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // No results found
                if (_controller.searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: colors.textLight),
                        const SizedBox(height: 12),
                        Text(
                          Keys.No_messages_found.tr,
                          style: ChatTextStyles.body.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final resultCount = _controller.searchResults.length;

                // Results list with cards
                return Column(
                  children: [
                    // Result count
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$resultCount ${resultCount == 1 ? 'result' : 'results'} found',
                          style: ChatTextStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        itemCount: resultCount,
                        itemBuilder: (context, index) {
                          final result = _controller.searchResults[index];
                          return _SearchResultCard(
                            result: result,
                            searchQuery: _searchController.text,
                            colors: colors,
                            onTap: () async {
                              final messageId = result['id'] as String;
                              _controller.toggleSearch();
                              await _controller.scrollToMessage(messageId);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card-style search result tile ───────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.result,
    required this.searchQuery,
    required this.colors,
    required this.onTap,
  });

  final Map<String, dynamic> result;
  final String searchQuery;
  final ChatColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final senderName = (result['senderName'] ?? result['sender_name'] ?? '') as String;
    final content = (result['content'] ?? '') as String;
    final createdAtStr = result['createdAt'] ?? result['created_at'];
    final createdAt = createdAtStr is String
        ? DateTime.tryParse(createdAtStr)?.toLocal()
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: colors.inputBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name + date/time row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        senderName,
                        style: ChatTextStyles.captionSemiBold.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(createdAt),
                        style: ChatTextStyles.messageTimestamp.copyWith(
                          color: colors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Content with highlighted match
                _buildHighlightedText(content),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text) {
    if (searchQuery.isEmpty) {
      return Text(
        text,
        style: ChatTextStyles.body.copyWith(color: colors.textSecondary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: ChatTextStyles.body.copyWith(color: colors.textSecondary),
        ));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: ChatTextStyles.body.copyWith(color: colors.textSecondary),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + searchQuery.length),
        style: ChatTextStyles.bodySemiBold.copyWith(
          color: colors.primaryColor,
          backgroundColor: colors.primaryColor.withValues(alpha: 0.1),
        ),
      ));
      start = index + searchQuery.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatDateTime(DateTime date) {
    final time = _formatTime(date);
    if (date.isToday) return time;
    if (date.isYesterday) return '${Keys.Yesterday.tr}, $time';

    final day = date.day.toString().padLeft(2, '0');
    final month = _monthAbbrev(date.month);
    if (date.isThisYear) return '$day $month, $time';
    return '$day $month ${date.year}, $time';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _monthAbbrev(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
