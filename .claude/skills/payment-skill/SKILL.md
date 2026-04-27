---
name: payment-skill
description: Use when implementing payment processing, Razorpay integration, PhonePe integration, order creation, payment verification, refunds, and transaction management for design purchases and jobs.
argument-hint: [payment type or feature needed]
disable-model-invocation: true
---

## What This Skill Does

Generates complete payment processing system for Shree Krishna EMB with Razorpay & PhonePe integration, order management, payment verification, refund handling, and transaction tracking.

**Features:**
- ✅ Razorpay payment gateway integration
- ✅ PhonePe integration
- ✅ Multiple payment methods (UPI, Cards, Net Banking, Wallets)
- ✅ Order creation on payment success
- ✅ Payment verification & webhook handling
- ✅ Refund processing
- ✅ Invoice generation
- ✅ Transaction history & tracking
- ✅ Platform fee calculation
- ✅ GST handling
- ✅ Error handling & retry logic

## Step-by-Step Workflow

### Step 1: Understand Payment Requirements
- Payment type? (Design purchase, Job payment, Payout)
- Methods needed? (UPI, Cards, Wallets)
- Refund policy?
- GST applicable?
- Platform fee %?

### Step 2: Setup Razorpay & PhonePe

**Razorpay:**
- Create business account
- Get API keys (public + secret)
- Setup webhooks for payment verification
- Configure refund settings

**PhonePe:**
- Register merchant account
- Get API credentials
- Setup merchant callbacks

### Step 3: Generate Payment DataSources

**Abstract:** `lib/data/datasources/payment_datasource.dart`
- `initiatePayment(orderId, amount)`
- `verifyPayment(paymentId, signature)`
- `initiateRefund(paymentId)`
- `getPaymentStatus(paymentId)`

**Razorpay Implementation:**
```dart
class RazorpayDataSource implements PaymentDataSource {
  - Use razorpay_flutter package
  - Initialize with API key
  - Handle payment sheet
  - Verify signature
}
```

**PhonePe Implementation:**
```dart
class PhonePeDataSource implements PaymentDataSource {
  - Use phonepe SDK
  - Handle merchant callbacks
  - Verify transaction
}
```

### Step 4: Generate Payment Models & Entities

**Entity:** `lib/domain/entities/payment.dart`
- paymentId
- orderId
- amount
- currency
- method (UPI, Card, etc.)
- status (pending, completed, failed, refunded)
- createdAt
- completedAt

**Order Entity:** `lib/domain/entities/order.dart`
- orderId
- userId
- items (designs or job)
- subtotal
- platformFee
- gst
- total
- paymentId
- status
- createdAt

### Step 5: Generate Payment Repository

**Interface:** `lib/domain/repositories/payment_repository.dart`
- `initiatePayment(order)`
- `verifyPayment(paymentId, signature)`
- `initiateRefund(paymentId)`
- `getPaymentHistory(userId)`
- `getTransaction(transactionId)`

**Implementation:** `lib/data/repositories/payment_repository_impl.dart`
- Wrap both Razorpay & PhonePe datasources
- Handle failures
- Create orders in Firestore on success

### Step 6: Generate Payment BLoCs

**CartBloc:**
- Add/remove items
- Update quantities
- Calculate totals
- Store cart locally (Hive)

**CheckoutBloc:**
- Prepare order for payment
- Handle payment initiation
- Verify payment response
- Create order on success

**PaymentHistoryBloc:**
- Load user transactions
- Filter & search
- Handle pagination

### Step 7: Generate Checkout UI Screens

**Paths:**
- `lib/screens/payment/cart_screen.dart`
- `lib/screens/payment/checkout_summary_screen.dart`
- `lib/screens/payment/payment_methods_screen.dart`
- `lib/screens/payment/payment_processing_screen.dart`
- `lib/screens/payment/order_success_screen.dart`
- `lib/screens/payment/order_history_screen.dart`
- `lib/screens/payment/invoice_viewer_screen.dart`

**Features:**
- Cart with swipe to delete
- Itemized breakdown (subtotal, fees, GST, total)
- Payment method selection
- Loading & processing states
- Order confirmation with receipt
- Invoice download

### Step 8: Implement Order Management

**Path:** `lib/domain/repositories/order_repository.dart`

Functions:
- `createOrder(orderData)` - Create order in Firestore
- `updateOrderStatus(orderId, status)`
- `getOrder(orderId)`
- `getUserOrders(userId)`

**Order Statuses:**
- pending_payment
- payment_verified
- completed
- failed
- refunded
- refund_pending

### Step 9: Generate Platform Fee Calculator

**Path:** `lib/core/utils/fee_calculator.dart`

```dart
class FeeCalculator {
  static calculatePlatformFee(amount, category) {
    // Default: 12%, Category overrides in admin settings
    return amount * 0.12;
  }
  
  static calculateGST(subtotal) {
    // GST: 18% on platform fee
    return platformFee * 0.18;
  }
  
  static calculateTotal(subtotal, platformFee, gst) {
    return subtotal + platformFee + gst;
  }
}
```

### Step 10: Implement Webhook Handling

**Path:** `lib/data/datasources/webhook_handler.dart`

Handle:
- Razorpay webhooks (payment.authorized, payment.failed)
- PhonePe callbacks (transaction status)
- Verify signatures
- Update order status
- Send notifications to users

### Step 11: Generate Refund System

**Path:** `lib/domain/usecases/refund_usecase.dart`

Functions:
- `initiateRefund(paymentId, reason)`
- `getRefundStatus(refundId)`
- `refundToWallet(amount)` - For in-app wallet
- `refundToBank(amount)` - Bank transfer

**Refund Process:**
1. User requests refund
2. Admin approves
3. Initiate refund via Razorpay/PhonePe
4. Verify refund completion
5. Update order status
6. Send notification

### Step 12: Generate Invoice System

**Path:** `lib/domain/usecases/invoice_usecase.dart`

Features:
- Generate PDF invoice
- Include order details
- GST breakdown
- Payment method
- Invoice number & date
- Download & email options

**Use:** `pdf` package for PDF generation

### Step 13: Setup Payment Security

**CRITICAL:**
- Store API secrets in Firebase Cloud Functions (not in app)
- Use backend for payment verification (never client-side)
- Implement payment signature verification
- Add fraud detection
- Rate limit payment attempts
- Use HTTPS only

**Implementation:**
- Create Firebase Cloud Function for payment verification
- Function receives payment details from app
- Verifies signature with Razorpay/PhonePe
- Updates Firestore order status
- Returns success/failure to app

### Step 14: Generate Service Locator Setup

```dart
// Payment sources (both for flexibility)
getIt.registerSingleton<PaymentDataSource>(
  RazorpayDataSource(razorpayKey: getIt()),
);

// Payment repository
getIt.registerSingleton<PaymentRepository>(
  PaymentRepositoryImpl(dataSource: getIt()),
);

// BLoCs
getIt.registerSingleton<CartBloc>(CartBloc());
getIt.registerSingleton<CheckoutBloc>(CheckoutBloc(getIt()));
getIt.registerSingleton<PaymentHistoryBloc>(PaymentHistoryBloc(getIt()));
```

### Step 15: Add Error Handling

**Common Errors:**
- Payment declined
- Network timeout
- Invalid order
- Refund failed
- Signature mismatch

**Handling:**
- Show user-friendly error messages
- Provide retry options
- Log errors for monitoring
- Contact support fallback

### Step 16: Generate Admin Payment Management

**For Admin App:**
- View all transactions
- Filter by date, status, role
- Export to CSV/Excel
- Initiate refunds
- Dispute handling

### Step 17: Provide Documentation

Output:
- Payment flow diagram
- Razorpay setup guide
- PhonePe setup guide
- Webhook setup instructions
- Firebase Cloud Function for verification
- Security best practices
- Testing with test cards

---

## Phase 1 MVP Checklist

**MVP (Phase 1):**
- ✅ Razorpay integration (primary)
- ✅ UPI + Card payment methods
- ✅ Order creation on payment success
- ✅ Invoice download
- ✅ Order history
- ⏭️ PhonePe integration (Phase 2)
- ⏭️ Advanced refunds (Phase 2)

---

## Security Guardrails

**MUST:**
- ✅ Never store full card details
- ✅ Always verify payment on backend
- ✅ Use HTTPS for all payment APIs
- ✅ Validate signatures
- ✅ Implement rate limiting
- ✅ Log all payment events

**NEVER:**
- ❌ Store API secret in app code
- ❌ Trust client-side verification
- ❌ Skip signature validation
- ❌ Expose payment IDs in logs
- ❌ Allow repeated same transaction

---

**Ready! Describe your payment needs.**
