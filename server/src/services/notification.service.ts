import { getMessaging } from '../config/firebase';
import { query } from '../config/database';
import { logger } from '../utils/logger';

interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

class NotificationService {
  async sendToUser(userId: string, payload: PushPayload): Promise<void> {
    const messaging = getMessaging();
    if (!messaging) {
      logger.debug('Push notifications disabled; Firebase not configured');
      return;
    }

    try {
      // Get all active devices with FCM tokens for the user
      const result = await query<{ fcm_token: string }>(
        `SELECT fcm_token FROM devices
         WHERE user_id = $1 AND is_active = true AND fcm_token IS NOT NULL`,
        [userId]
      );

      if (result.rows.length === 0) {
        logger.debug('No active devices with FCM tokens for user');
        return;
      }

      const tokens = result.rows.map((r) => r.fcm_token);

      const response = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data,
        android: {
          priority: 'high',
          notification: {
            channelId: 'medical_chat',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              contentAvailable: true,
            },
          },
        },
      });

      // Handle failed tokens
      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const errorCode = resp.error?.code;
            if (
              errorCode === 'messaging/invalid-registration-token' ||
              errorCode === 'messaging/registration-token-not-registered'
            ) {
              failedTokens.push(tokens[idx]);
            }
          }
        });

        if (failedTokens.length > 0) {
          await query(
            `UPDATE devices SET fcm_token = NULL, is_active = false
             WHERE fcm_token = ANY($1)`,
            [failedTokens]
          );
          logger.info('Deactivated invalid FCM tokens', { count: failedTokens.length });
        }
      }
    } catch (error) {
      logger.error('Failed to send push notification', {
        error: error instanceof Error ? error.message : 'Unknown',
        userId,
      });
    }
  }

  async sendToConversationParticipants(
    conversationId: string,
    excludeUserId: string,
    payload: PushPayload
  ): Promise<void> {
    const result = await query<{ user_id: string }>(
      `SELECT user_id FROM conversation_participants
       WHERE conversation_id = $1 AND user_id != $2 AND left_at IS NULL AND is_muted = false`,
      [conversationId, excludeUserId]
    );

    const sendPromises = result.rows.map((r) =>
      this.sendToUser(r.user_id, payload)
    );

    await Promise.allSettled(sendPromises);
  }
}

export const notificationService = new NotificationService();
