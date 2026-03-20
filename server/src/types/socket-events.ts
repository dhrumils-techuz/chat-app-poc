export const SOCKET_EVENTS = {
  // Client -> Server
  MESSAGE_SEND: 'message:send',
  MESSAGE_DELETE: 'message:delete',
  TYPING_START: 'typing:start',
  TYPING_STOP: 'typing:stop',
  PRESENCE_ONLINE: 'presence:online',
  PRESENCE_OFFLINE: 'presence:offline',
  MESSAGE_DELIVERED: 'message:delivered',
  MESSAGE_READ: 'message:read',
  JOIN_CONVERSATIONS: 'conversations:join',

  // Server -> Client
  MESSAGE_NEW: 'message:new',
  MESSAGE_SENT: 'message:sent',
  MESSAGE_DELETED: 'message:deleted',
  MESSAGE_DELIVERED_ACK: 'message:delivered:ack',
  MESSAGE_READ_ACK: 'message:read:ack',
  TYPING_INDICATOR: 'typing:indicator',
  PRESENCE_UPDATE: 'presence:update',
  ERROR: 'error',
} as const;

export interface ClientToServerEvents {
  'message:send': (data: {
    conversationId: string;
    type: string;
    content?: string;
    mediaId?: string;
    replyToId?: string;
    localId: string;
  }, callback: (response: { success: boolean; messageId?: string; error?: string }) => void) => void;

  'message:delete': (data: {
    conversationId: string;
    messageId: string;
    forEveryone: boolean;
  }) => void;

  'message:delivered': (data: { messageId: string; conversationId: string }) => void;

  'message:read': (data: { messageId: string; conversationId: string }) => void;

  'typing:start': (data: { conversationId: string }) => void;

  'typing:stop': (data: { conversationId: string }) => void;

  'presence:online': () => void;

  'presence:offline': () => void;

  'conversations:join': (data: { conversationIds: string[] }) => void;
}

export interface ServerToClientEvents {
  'message:new': (data: {
    id: string;
    conversationId: string;
    senderId: string;
    senderName: string;
    type: string;
    content: string | null;
    mediaId: string | null;
    replyToId: string | null;
    replyToContent: string | null;
    replyToSenderName: string | null;
    createdAt: string;
  }) => void;

  'message:sent': (data: {
    localId: string;
    messageId: string;
    conversationId: string;
    senderId: string;
    senderName: string;
    type: string;
    content: string | null;
    mediaId: string | null;
    replyToId: string | null;
    replyToContent: string | null;
    replyToSenderName: string | null;
    createdAt: string;
  }) => void;

  'message:deleted': (data: {
    messageId: string;
    conversationId: string;
    forEveryone: boolean;
  }) => void;

  'message:delivered:ack': (data: {
    messageId: string;
    userId: string;
    timestamp: string;
  }) => void;

  'message:read:ack': (data: {
    messageId: string;
    userId: string;
    timestamp: string;
  }) => void;

  'typing:indicator': (data: {
    conversationId: string;
    userId: string;
    userName: string;
    isTyping: boolean;
  }) => void;

  'presence:update': (data: {
    userId: string;
    status: 'online' | 'offline';
    lastSeenAt: string;
  }) => void;

  'error': (data: { message: string; code?: string }) => void;
}
