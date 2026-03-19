import 'package:flutter/material.dart';

import '../../../../core/theme/color.dart';
import '../../../data/types/message_status_type.dart';

class MessageStatusIndicator extends StatelessWidget {
  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.size = 16,
  });

  final MessageStatusType status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    switch (status) {
      case MessageStatusType.sending:
        return Icon(
          Icons.access_time,
          size: size * 0.75,
          color: colors.textTimestamp,
        );
      case MessageStatusType.sent:
        return Icon(
          Icons.done,
          size: size,
          color: colors.textTimestamp,
        );
      case MessageStatusType.delivered:
        return Icon(
          Icons.done_all,
          size: size,
          color: colors.textTimestamp,
        );
      case MessageStatusType.read:
        return Icon(
          Icons.done_all,
          size: size,
          color: colors.readReceiptColor,
        );
      case MessageStatusType.failed:
        return Icon(
          Icons.error_outline,
          size: size,
          color: colors.errorColor,
        );
    }
  }
}
