---
name: rating-review-skill
description: Use when implementing review systems, star ratings, designer verification badges, review moderation, and rating analytics for jobs and designs.
argument-hint: [rating feature: submit, display, or moderate]
disable-model-invocation: true
---

## What This Skill Does

Generates complete rating and review system for designs and jobs with star ratings, moderation, badges, and analytics.

**Features:**
- ✅ Submit reviews & ratings (1-5 stars)
- ✅ Review approval workflow (prevent spam)
- ✅ Designer verification badges
- ✅ Average rating calculations
- ✅ Review history & pagination
- ✅ Review search & filtering
- ✅ Helpful votes (up/down)
- ✅ Review moderation queue
- ✅ Rating analytics

## Key Models

```dart
class Review {
  String reviewId;
  String designId; // or jobId
  String reviewerId;
  String targetId; // designerId or clientId
  double rating; // 1-5
  String text;
  List<String>? images;
  int helpfulVotes;
  String status; // pending, approved, rejected
  DateTime createdAt;
}

class DesignerMetrics {
  String designerId;
  double averageRating;
  int totalReviews;
  Map<int, int> ratingDistribution; // {5: 100, 4: 50, ...}
}
```

## Implementation

### 1. Firestore Structure
```
/reviews/{reviewId}
  ├── designId / jobId
  ├── reviewerId
  ├── targetId
  ├── rating
  ├── text
  ├── status (pending → approved)
  ├── createdAt

/designs/{designId}/metrics
  ├── averageRating
  ├── totalReviews
  ├── ratingDistribution
```

### 2. Review Workflow
- User submits review
- Firestore trigger: create review with status: pending
- Admin moderation queue
- Admin approves → updates metrics
- Designer notified

### 3. Rating Display
- Show on design detail screen
- Designer profile rating badge
- Verified designer badge (5+ reviews, 4.5+ rating)
- Review breakdown (distribution chart)

### 4. Moderation
Admin screens:
- Pending reviews queue
- Approve/reject with reason
- Delete flagged reviews
- View user's review history

### 5. Helpful Votes
```dart
Review.helpfulVotes++ when user votes helpful
```

### 6. Review Search
Filter by:
- Rating (5 stars, 4+ stars, etc.)
- Date range
- Reviewer name
- Helpful (sort by votes)

---

**Phase 2:** Basic reviews, ratings  
**Phase 3+:** Review images, helpful votes

---

Ready for reviews!
