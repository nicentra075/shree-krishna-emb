---
name: wallet-payout-skill
description: Use when implementing designer wallet system, payout requests, earnings tracking, transaction history, bank account verification, and payout management for Phase 2+ features.
argument-hint: [wallet feature: earnings, payout, or verification]
disable-model-invocation: true
---

## What This Skill Does

Generates complete wallet and payout system for designers with earnings tracking, payout requests, bank account verification, transaction history, and admin payout management.

**Features:**
- ✅ Designer wallet with balance tracking
- ✅ Earnings from design sales & job completion
- ✅ Payout request workflow
- ✅ Bank account verification
- ✅ Transaction history
- ✅ Admin payout approval/processing
- ✅ Payment to bank (via Razorpay Payouts)
- ✅ Minimum payout threshold
- ✅ Earnings calculator
- ✅ Withdrawal status tracking

## Key Models

```dart
class DesignerWallet {
  String designerId;
  double grossSales;
  double platformFees;
  double netEarnings;
  double availableBalance;
  double pendingBalance;
  DateTime lastPayoutDate;
}

class Earning {
  String earningId;
  String designerId;
  double amount;
  String source; // design_sale, job_completion, referral
  String sourceId;
  DateTime date;
}

class PayoutRequest {
  String requestId;
  String designerId;
  double amount;
  String status; // pending, approved, processing, completed, rejected
  DateTime requestedDate;
  String bankAccount;
  DateTime processingDate;
}
```

## Implementation Steps

### 1. Firestore Structure

```
/designers/{designerId}/wallet
  ├── grossSales
  ├── platformFees
  ├── netEarnings
  ├── availableBalance

/designers/{designerId}/earnings/{earningId}
  ├── amount
  ├── source
  ├── sourceId
  ├── date

/payouts/{payoutId}
  ├── designerId
  ├── amount
  ├── status
  ├── bankAccount
  ├── dates...
```

### 2. Wallet Repository

**Path:** `lib/domain/repositories/wallet_repository.dart`

Functions:
- `getWallet(designerId)`
- `getEarnings(designerId)`
- `addEarning(earning)`
- `requestPayout(designerId, amount)`
- `getPayout(payoutId)`
- `updatePayoutStatus(payoutId, status)`

### 3. Bank Account Verification

**Path:** `lib/domain/usecases/verify_bank_account_usecase.dart`

Steps:
1. Designer enters bank details
2. Backend verifies with bank (micro-deposit verification)
3. Designer confirms micro-deposits
4. Account activated for payouts

Use Razorpay Bank Account Verification API

### 4. Earnings Calculation

When design is sold or job completed:
```dart
// Add earning
final earning = Earning(
  designerId: designerId,
  amount: designPrice,
  source: 'design_sale',
  sourceId: designId,
);

// Update wallet
final platformFee = designPrice * 0.12;
wallet.grossSales += designPrice;
wallet.platformFees += platformFee;
wallet.netEarnings = wallet.grossSales - wallet.platformFees;
wallet.availableBalance = wallet.netEarnings;
```

### 5. Payout Request Flow

1. Designer views wallet balance
2. Enters payout amount
3. Clicks "Request Payout"
4. System creates PayoutRequest (status: pending)
5. Admin sees pending payouts
6. Admin approves → status: approved
7. Backend initiates Razorpay Payout → status: processing
8. Razorpay completes → status: completed
9. Designer receives notification + money in bank

### 6. Razorpay Payouts Integration

Use Razorpay Payouts API (requires backend):

```javascript
// Firebase Cloud Function
const payoutResponse = await razorpay.payouts.create({
  account_number: designerBankAccount,
  amount: payoutAmount,
  currency: 'INR',
  mode: 'NEFT', // or IMPS for faster
  purpose: 'payout',
  queue_if_low_balance: true,
  reference_id: payoutRequestId,
});
```

### 7. Minimum Payout Threshold

Require minimum balance before payout request:
- Minimum: ₹100 or configurable by admin
- Show "Available for payout" calculation

### 8. Designer Wallet Screen

**Path:** `lib/screens/designer/wallet_screen.dart`

Shows:
- Balance cards (Gross, Platform Fees, Net)
- Available for payout
- Earnings breakdown (chart)
- Recent transactions
- "Request Payout" button

### 9. Payout Request Dialog

Steps:
1. Enter amount (with balance validation)
2. Select bank account (if multiple)
3. Confirm details
4. Submit request

### 10. Admin Payout Management

**Path:** `lib/screens/admin/payouts_screen.dart`

Features:
- List pending payout requests
- Approve/reject
- View designer details
- Process payout (initiate transfer)
- Mark as completed
- Bulk actions

### 11. Transaction History

**Path:** `lib/screens/designer/transaction_history_screen.dart`

Shows:
- All earnings (paginated)
- All payouts
- Filter by date, type
- Export to CSV
- Search

### 12. Security & Validation

- Bank account verification required before payout
- Admin-only approval of payouts
- Prevent duplicate payouts (reference_id)
- Audit trail of all transactions
- Rate limit payout requests

### 13. Notifications

Send notifications when:
- Earning added to wallet
- Payout approved
- Payout completed
- Payout rejected

---

**Phase 2 MVP:** Wallet display, payout requests, admin approval  
**Phase 3+:** Partial payouts, instant transfers, wallet credit

---

**Ready for designer earnings!**
