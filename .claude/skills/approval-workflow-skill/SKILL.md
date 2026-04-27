---
name: approval-workflow-skill
description: Use when implementing content approval queues, designer verification workflows, design review & rejection systems, and admin moderation for Phase 2+ features.
argument-hint: [workflow type: designer verification or content approval]
disable-model-invocation: true
---

## What This Skill Does

Generates complete approval workflows for designer verification and design content moderation with queue management, rejection reasons, and bulk actions.

## Key Features

- ✅ Designer verification workflow (ID & portfolio review)
- ✅ Design approval queue (new designs waiting approval)
- ✅ Bulk approve/reject actions
- ✅ Rejection reason templates
- ✅ Designer notifications
- ✅ Appeal process
- ✅ Verification badge display
- ✅ Admin audit trail

## Implementation

### Firestore Structure
```
/designerVerifications/{designerId}
  ├── status: pending | verified | rejected
  ├── portfolio: [images]
  ├── idProof: url
  ├── specialties: [list]
  ├── submittedDate
  ├── verifiedDate
  ├── rejectionReason

/designApprovals/{designId}
  ├── status: pending | approved | rejected
  ├── submittedBy: designerId
  ├── submittedDate
  ├── reviewedBy: adminId
  ├── rejectionReason
```

### Workflows

**Designer Verification:**
1. Signup → Submit portfolio + ID
2. Admin reviews (portfolio quality, ID validity)
3. Approve → Badge awarded, notifications sent
4. Reject → Reason sent, option to resubmit

**Design Approval:**
1. Designer uploads design
2. Admin queue shows pending designs
3. Admin reviews (image quality, metadata, policy compliance)
4. Approve → Public listing, notifications
5. Reject → Reason sent, option to edit & resubmit

### Admin Screens

1. Pending Designer Queue
   - Portfolio preview, ID verification
   - Approve/Reject buttons
   - Bulk actions

2. Pending Design Queue
   - Design preview with watermark
   - Metadata review
   - Approve/Reject with reason

3. Approval History
   - Audit trail
   - Filter by status, date
   - Export to CSV

---

**Phase 2:** Designer verification, design approval  
**Phase 3+:** Appeals, resubmission tracking

---

Ready for content moderation!
