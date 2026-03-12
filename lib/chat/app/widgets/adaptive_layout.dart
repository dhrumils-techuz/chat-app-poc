import 'package:flutter/material.dart';

import '../../core/theme/color.dart';
import '../../core/utils/screen_util.dart';

/// A responsive layout widget that switches between mobile and split-view
/// (tablet/desktop) layouts based on screen width.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.listPanel,
    this.detailPanel,
    this.showDetailPanel = false,
    this.listPanelWidth,
    this.onBackFromDetail,
    this.splitViewBreakpoint = 600,
  });

  /// The list panel (e.g., conversation list).
  final Widget listPanel;

  /// The detail panel (e.g., chat detail).
  final Widget? detailPanel;

  /// Whether to show the detail panel on mobile (used for navigation).
  final bool showDetailPanel;

  /// Custom width for the list panel in split view. Defaults to 350.
  final double? listPanelWidth;

  /// Minimum screen width to enable split view. Defaults to 600.
  final double splitViewBreakpoint;

  /// Callback when navigating back from detail on mobile.
  final VoidCallback? onBackFromDetail;

  @override
  Widget build(BuildContext context) {
    final isSplitView = ScreenUtil.width(context) >= splitViewBreakpoint;
    final colors = ChatColors.getInstance(context);

    if (isSplitView) {
      return _buildSplitView(context, colors);
    }

    return _buildMobileView(context);
  }

  Widget _buildSplitView(BuildContext context, ChatColors colors) {
    final panelWidth = listPanelWidth ?? 350;

    return Row(
      children: [
        SizedBox(
          width: panelWidth,
          child: listPanel,
        ),
        Container(
          width: 1,
          color: colors.dividerColor,
        ),
        Expanded(
          child: detailPanel ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: colors.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a conversation',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildMobileView(BuildContext context) {
    if (showDetailPanel && detailPanel != null) {
      return detailPanel!;
    }
    return listPanel;
  }
}
