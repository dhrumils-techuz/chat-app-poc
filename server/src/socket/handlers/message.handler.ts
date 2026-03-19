import { Socket, Server } from 'socket.io';
import { messageService } from '../../services/message.service';
import { conversationService } from '../../services/conversation.service';
import { notificationService } from '../../services/notification.service';
import { SOCKET_EVENTS } from '../../types/socket-events';
import { JwtPayload } from '../../types';
import { logger } from '../../utils/logger';
import { query } from '../../config/database';

export function handleMessageEvents(socket: Socket, io: Server, auth: JwtPayload): void {
  const { userId, tenantId } = auth;

  socket.on(SOCKET_EVENTS.MESSAGE_SEND, async (data, callback) => {
    try {
      const { conversationId, type, content, mediaId, replyToId, localId } = data;

      if (!conversationId || !type || !localId) {
        callback({ success: false, error: 'Missing required fields' });
        return;
      }

      const message = await messageService.sendMessage({
        conversationId,
        senderId: userId,
        tenantId,
        type,
        content,
        mediaId,
        replyToId,
      });

      let replyToContent: string | null = null;
      let replyToSenderName: string | null = null;

      if (replyToId) {
        try {
          const replyMsg = await query(
            `SELECT m.content, u.full_name as sender_name
             FROM messages m JOIN users u ON u.id = m.sender_id
             WHERE m.id = $1`,
            [replyToId]
          );
          if (replyMsg.rows.length > 0) {
            replyToContent = replyMsg.rows[0].content;
            replyToSenderName = replyMsg.rows[0].sender_name;
          }
        } catch (e) {
          // Non-critical, continue without reply details
        }
      }

      // Acknowledge to sender with server message ID
      callback({
        success: true,
        messageId: message.id,
      });

      // Send confirmed message back to sender (include full details so
      // other controllers like ChatListController can update their state)
      socket.emit(SOCKET_EVENTS.MESSAGE_SENT, {
        localId,
        messageId: message.id,
        conversationId,
        senderName: message.sender_name,
        type: message.type,
        content: message.content,
        replyToId: message.reply_to_id,
        replyToContent,
        replyToSenderName,
        createdAt: message.created_at.toISOString ? message.created_at.toISOString() : String(message.created_at),
      });

      // Broadcast to conversation room (excluding sender)
      socket.to(`conversation:${conversationId}`).emit(SOCKET_EVENTS.MESSAGE_NEW, {
        id: message.id,
        conversationId,
        senderId: userId,
        senderName: message.sender_name,
        type: message.type,
        content: message.content,
        mediaId: message.media_id,
        replyToId: message.reply_to_id,
        replyToContent,
        replyToSenderName,
        createdAt: message.created_at.toISOString ? message.created_at.toISOString() : String(message.created_at),
      });

      // Send push notifications to offline participants
      const senderName = message.sender_name;
      let notificationBody = '';
      switch (type) {
        case 'text':
          notificationBody = content || '';
          break;
        case 'image':
          notificationBody = 'Sent an image';
          break;
        case 'audio':
          notificationBody = 'Sent an audio message';
          break;
        case 'document':
          notificationBody = 'Sent a document';
          break;
        default:
          notificationBody = 'New message';
      }

      // Fetch conversation details for the push notification
      let conversationName: string | null = null;
      let conversationType = 'direct';
      try {
        const convResult = await query<{ name: string | null; type: string }>(
          'SELECT name, type FROM conversations WHERE id = $1',
          [conversationId]
        );
        if (convResult.rows.length > 0) {
          conversationName = convResult.rows[0].name;
          conversationType = convResult.rows[0].type;
        }
      } catch (_) {
        // Non-critical
      }

      // For group chats, show "Sender in GroupName" as the title
      const notificationTitle = conversationType === 'group' && conversationName
        ? `${senderName} in ${conversationName}`
        : senderName;

      notificationService
        .sendToConversationParticipants(conversationId, userId, {
          title: notificationTitle,
          body: notificationBody,
          data: {
            conversationId,
            messageId: message.id,
            type: 'new_message',
            senderName,
            conversationName: conversationName || '',
            conversationType,
          },
        })
        .catch((err) => logger.error('Failed to send push notifications', { error: err.message }));
    } catch (error) {
      logger.error('Error handling message:send', {
        error: error instanceof Error ? error.message : 'Unknown',
        userId,
      });
      callback({ success: false, error: 'Failed to send message' });
    }
  });

  socket.on(SOCKET_EVENTS.MESSAGE_DELETE, async (data) => {
    try {
      const { conversationId, messageId, forEveryone } = data;

      if (!conversationId || !messageId) return;

      if (forEveryone) {
        await messageService.deleteMessage(messageId, conversationId, userId, tenantId);

        // Broadcast deletion to all participants in the conversation
        io.to(`conversation:${conversationId}`).emit(SOCKET_EVENTS.MESSAGE_DELETED, {
          messageId,
          conversationId,
          forEveryone: true,
        });
      } else {
        // "Delete for me" — mark as deleted for this user only.
        // The message will be filtered out when this user fetches messages.
        await messageService.deleteMessageForUser(messageId, userId);
      }
    } catch (error) {
      logger.error('Error handling message:delete', {
        error: error instanceof Error ? error.message : 'Unknown',
        userId,
      });
    }
  });
}
