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

      // Acknowledge to sender with server message ID
      callback({
        success: true,
        messageId: message.id,
      });

      // Send confirmed message back to sender
      socket.emit(SOCKET_EVENTS.MESSAGE_SENT, {
        localId,
        messageId: message.id,
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

      notificationService
        .sendToConversationParticipants(conversationId, userId, {
          title: senderName,
          body: notificationBody,
          data: {
            conversationId,
            messageId: message.id,
            type: 'new_message',
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
}
