---
name: chat-skill
description: Use when implementing real-time in-app messaging between users and designers, chat history, typing indicators, message notifications, and job communication features using Firestore.
argument-hint: [chat feature: messaging, notifications, or history]
disable-model-invocation: true
---

## What This Skill Does

Generates complete real-time chat system for Shree Krishna using Firestore with instant messaging, typing indicators, online status, message history, and notifications.

**Features:**
- ✅ Real-time messaging (Firestore listeners)
- ✅ Typing indicators
- ✅ Online/offline status
- ✅ Message read receipts
- ✅ Message history with pagination
- ✅ File sharing in chat
- ✅ Chat notifications
- ✅ Search messages
- ✅ Block users
- ✅ Message reports (abuse)

## Workflow

### 1. Firestore Structure

```
/chats/{chatId}/
  ├── metadata (created, participants, lastMessage, unreadCount)
  └── messages/{messageId}
      ├── senderId
      ├── content
      ├── timestamp
      ├── status (sent, delivered, read)
      ├── attachments[]
```

### 2. Chat Models

```dart
class Chat {
  String chatId;
  List<String> participantIds;
  String lastMessage;
  DateTime lastMessageTime;
  Map<String, int> unreadCounts; // Per user
}

class Message {
  String messageId;
  String chatId;
  String senderId;
  String content;
  DateTime timestamp;
  String status; // sent, delivered, read
  List<Attachment>? attachments;
}

class Attachment {
  String type; // image, file, video
  String url;
  String fileName;
}
```

### 3. Chat Repository

**Path:** `lib/domain/repositories/chat_repository.dart`

Functions:
- `getOrCreateChat(userId1, userId2)`
- `sendMessage(chatId, message)`
- `getMessage(messageId)`
- `getMessages(chatId, limit)` - Paginated
- `markAsRead(chatId, messageId)`
- `deleteMessage(messageId)`
- `searchMessages(chatId, query)`
- `blockUser(userId)`
- `getBlockedUsers()`

### 4. Real-time Message Listener

**Path:** `lib/bloc/chat/chat_bloc.dart`

Use Firestore snapshots:
```dart
_firestore
  .collection('chats/$chatId/messages')
  .orderBy('timestamp', descending: true)
  .limit(50)
  .snapshots()
  .listen((snapshot) {
    // Update messages in real-time
  });
```

### 5. Typing Indicators

Store typing status in Firestore:
```
/chats/{chatId}/typingStatus/{userId}
  ├── isTyping: bool
  ├── timestamp: DateTime (auto-remove after 5s)
```

Listener:
```dart
_firestore
  .collection('chats/$chatId/typingStatus')
  .snapshots()
  .listen((snapshot) {
    // Show "User is typing..."
  });
```

### 6. Online Status

Store user online status:
```
/users/{userId}/status
  ├── isOnline: bool
  ├── lastSeen: DateTime
```

Update on app foreground/background

### 7. Message Read Receipts

Track read status:
```dart
_firestore
  .collection('chats/$chatId/messages')
  .doc(messageId)
  .update({
    'status': 'read',
    'readBy': FieldValue.arrayUnion([currentUserId]),
    'readAt': FieldValue.serverTimestamp(),
  });
```

### 8. Chat Screen UI

**Path:** `lib/screens/chat/chat_screen.dart`

Features:
- Message list with date separators
- Input field with send button
- Typing indicator
- Online status badge
- Message actions (delete, report)
- Attachment preview
- Unread message indicator

### 9. Chat List Screen

**Path:** `lib/screens/chat/chat_list_screen.dart`

Shows:
- All active chats sorted by last message
- Unread count badge
- Last message preview
- User avatar & online status
- Search/filter chats

### 10. Message Notifications

When message received:
```dart
// Show in-app notification
AppSnackbar.show(context, 
  'New message from ${sender.name}',
  action: 'View'
);

// Push notification (via Cloud Functions)
```

### 11. File Sharing

Upload files to Firebase Storage:
```
/chats/{chatId}/attachments/{fileId}
```

Preview:
- Images: Inline in chat
- Documents: File icon with download
- Videos: Thumbnail with player

### 12. Search Messages

Use Firestore text search:
```dart
_firestore
  .collection('chats/$chatId/messages')
  .where('content', '>=', query)
  .where('content', '<=', query + 'z')
  .get();
```

Or build local search from cached messages

### 13. Block Users

```
/users/{userId}/blockedUsers = [...]
```

When user is blocked:
- Can't see chat
- Can't send messages
- Can't see online status

### 14: Security Rules

```javascript
match /chats/{chatId} {
  // Only participants can read
  allow read: if request.auth.uid in resource.data.participantIds;
  // Only creator can update metadata
  allow update: if resource.data.createdBy == request.auth.uid;
}

match /chats/{chatId}/messages/{messageId} {
  // Only chat participants
  allow read: if request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds;
  // Only sender can write
  allow write: if request.auth.uid == request.resource.data.senderId;
}
```

### 15. Chat BLoC

Events:
- `SendMessageEvent(message)`
- `LoadMessagesEvent(chatId)`
- `MarkAsReadEvent(messageId)`
- `SetTypingStatusEvent(isTyping)`
- `DeleteMessageEvent(messageId)`

States:
- `ChatLoading`
- `ChatLoaded(messages)`
- `MessageSent`
- `TypingStatusUpdated`
- `ChatError`

### 16. Performance Optimization

- Pagination: Load 50 messages at a time
- Virtual scrolling for long chats
- Cache messages locally (Hive)
- Debounce typing indicator
- Index timestamps for fast sorting

---

**Phase 2 MVP:** Basic messaging, typing indicators  
**Phase 3+:** Voice messages, video calls, reactions

---

**Ready for real-time chat!**
