---
name: notification-skill
description: Use when implementing push notifications, in-app notifications, notification preferences, email notifications, and notification history for all user events.
argument-hint: [notification type: push, in-app, or email]
disable-model-invocation: true
---

## What This Skill Does

Generates complete notification system with push notifications, in-app notifications, email notifications, and user preferences.

## Features

- ✅ Push notifications (Firebase Cloud Messaging)
- ✅ In-app notification center
- ✅ Email notifications (SendGrid/Firebase Email)
- ✅ Notification preferences
- ✅ Do-not-disturb scheduling
- ✅ Notification history
- ✅ Rich notification payloads
- ✅ Action buttons in notifications
- ✅ Notification analytics

## Types of Notifications

**Real-time events:**
- New bid received
- Job awarded
- Milestone completed
- Message received
- Review posted
- Design approved/rejected
- Payout processed
- Account alerts

**Scheduled:**
- Daily/weekly digests
- Pending approvals
- Expiring listings

### Implementation

**Firebase Cloud Functions:**
```javascript
// Trigger on event → Send notification
exports.onNewBidCreated = functions.firestore
  .document('jobs/{jobId}/bids/{bidId}')
  .onCreate(async (snap, context) => {
    const bid = snap.data();
    // Send push to job poster
    await sendPushNotification(
      jobOwnerId,
      'New bid on your job!',
      {type: 'bid', jobId: context.params.jobId}
    );
  });
```

**User Preferences:**
```
/users/{userId}/notificationPreferences
  ├── pushEnabled: true
  ├── emailEnabled: true
  ├── inAppEnabled: true
  ├── quietHours: {start: 22:00, end: 8:00}
  ├── disabledCategories: [marketing, digest]
```

---

**Phase 2:** Push & in-app notifications  
**Phase 3+:** Email digests, smart scheduling

---

Ready for notifications!
