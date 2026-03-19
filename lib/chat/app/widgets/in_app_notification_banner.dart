import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/color.dart';
import 'avatar_widget.dart';

/// Discord-style in-app notification banner.
/// Dark rounded card that slides in from the top with avatar,
/// sender/group info, and message preview.
class InAppNotificationBanner {
  static OverlayEntry? _currentEntry;
  static Timer? _autoDismissTimer;
  static GlobalKey<_DiscordBannerState>? _bannerKey;

  static void show({
    required BuildContext context,
    required String senderName,
    required String body,
    String? groupName,
    String? avatarName,
    String? avatarUrl,
    String? timestamp,
    VoidCallback? onTap,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    // Remove instantly if one is already showing (no animation for replacement)
    _removeEntry();

    final OverlayState? overlay;
    try {
      overlay = Navigator.of(context).overlay;
    } catch (_) {
      return;
    }
    if (overlay == null) return;

    final key = GlobalKey<_DiscordBannerState>();
    _bannerKey = key;

    _currentEntry = OverlayEntry(
      builder: (ctx) => _DiscordBanner(
        key: key,
        senderName: senderName,
        body: body,
        groupName: groupName,
        avatarName: avatarName ?? senderName,
        avatarUrl: avatarUrl,
        timestamp: timestamp,
        onTap: () {
          _animateOut(then: onTap);
        },
        onDismiss: _removeEntry,
      ),
    );

    overlay.insert(_currentEntry!);
    _autoDismissTimer = Timer(duration, dismiss);
  }

  /// Animated dismiss — slides the banner back up before removing.
  static void dismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _animateOut();
  }

  /// Triggers the reverse animation on the banner widget, then removes.
  static void _animateOut({VoidCallback? then}) {
    final state = _bannerKey?.currentState;
    if (state != null && state.mounted) {
      state.animateOut().then((_) {
        _removeEntry();
        then?.call();
      });
    } else {
      _removeEntry();
      then?.call();
    }
  }

  /// Instantly removes the overlay entry without animation.
  static void _removeEntry() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
    _bannerKey = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DiscordBanner extends StatefulWidget {
  const _DiscordBanner({
    super.key,
    required this.senderName,
    required this.body,
    required this.avatarName,
    this.groupName,
    this.avatarUrl,
    this.timestamp,
    this.onTap,
    this.onDismiss,
  });

  final String senderName;
  final String body;
  final String avatarName;
  final String? groupName;
  final String? avatarUrl;
  final String? timestamp;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  State<_DiscordBanner> createState() => _DiscordBannerState();
}

class _DiscordBannerState extends State<_DiscordBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Plays the reverse (slide up + fade out) animation.
  /// Returns a Future that completes when the animation finishes.
  Future<void> animateOut() {
    return _animController.reverse();
  }

  void _dismiss() {
    animateOut().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);
    final mediaQuery = MediaQuery.of(context);

    // Use app theme colors with Discord-style layout
    final cardColor = colors.surfaceColor;
    final textPrimary = colors.textPrimary;
    final textSecondary = colors.textSecondary;
    final textMuted = colors.textLight;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -80) {
                _dismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: EdgeInsets.only(
                  top: mediaQuery.padding.top + 8,
                  left: 12,
                  right: 12,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: colors.primaryColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar with green online dot ──
                    Stack(
                      children: [
                        AvatarWidget(
                          imageUrl: widget.avatarUrl,
                          name: widget.avatarName,
                          size: 40,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cardColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // ── Content ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top row: title + time
                          // DM:    "David Rep  2:30 PM"
                          // Group: "Group X  2:30 PM"
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.groupName ?? widget.senderName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.timestamp != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  widget.timestamp!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textMuted,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Message preview
                          // DM:    "Hey, are you free..."
                          // Group: "David: Hey, are you free..."
                          Text.rich(
                            TextSpan(
                              children: [
                                if (widget.groupName != null)
                                  TextSpan(
                                    text: '${widget.senderName}: ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                TextSpan(
                                  text: widget.body,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // ── Close button ──
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
