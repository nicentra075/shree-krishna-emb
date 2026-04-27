---
name: analytics-skill
description: Use when implementing admin analytics dashboards, KPI tracking, revenue charts, user metrics, sales analytics, designer performance reports, and data export features.
argument-hint: [analytics type: dashboard, charts, or reports]
disable-model-invocation: true
---

## What This Skill Does

Generates complete analytics system for Shree Krishna admin dashboard with KPI tracking, real-time charts, sales reports, user metrics, and CSV/Excel export.

**Features:**
- ✅ KPI dashboard (users, transactions, revenue)
- ✅ Revenue trends (daily, weekly, monthly)
- ✅ User acquisition charts
- ✅ Top-selling designs analytics
- ✅ Designer performance metrics
- ✅ Transaction filtering & export
- ✅ Real-time data updates
- ✅ CSV/Excel export
- ✅ Date range filtering
- ✅ Custom report generation

## Workflow

### 1. Analytics Models

```dart
class KPI {
  int totalUsers;
  int totalDesigners;
  int totalTransactions;
  double totalRevenue;
  double platformFeesCollected;
  int pendingApprovals;
  DateTime lastUpdated;
}

class RevenueMetric {
  DateTime date;
  double amount;
  int transactionCount;
}

class DesignerMetric {
  String designerId;
  String name;
  int jobsCompleted;
  double totalEarnings;
  double averageRating;
}
```

### 2. Analytics Repository

**Path:** `lib/domain/repositories/analytics_repository.dart`

Functions:
- `getKPIs()` - Dashboard KPIs
- `getRevenueMetrics(startDate, endDate)`
- `getUserAcquisition(startDate, endDate)`
- `getTopDesigns(limit, timeframe)`
- `getTopDesigners(limit, timeframe)`
- `getTransactions(filters)`
- `exportData(format, data)`

### 3. Firestore Queries

**Collection:** `/analytics/admin/`

Store aggregated data:
- Daily revenue
- Daily user signups
- Daily transactions
- Designer metrics snapshot

**Why aggregation:** Real-time computation on large datasets is slow

### 4. Dashboard Screen

**Path:** `lib/screens/admin/dashboard_screen.dart`

Widgets:
- KPI cards (users, revenue, transactions)
- Revenue chart (line chart with date range)
- User acquisition chart
- Recent activity feed
- Pending approvals count

### 5. Charts Implementation

Use `fl_chart` package:
- LineChart for revenue trends
- BarChart for user acquisition
- PieChart for category breakdown
- Cards for KPI display

### 6. Reports Screen

**Path:** `lib/screens/admin/reports_screen.dart`

Features:
- Date range picker
- Filter options (category, designer, status)
- View results in table
- Export button
- Preset reports (This week, This month, All time)

### 7. Export Functionality

**Path:** `lib/domain/usecases/export_usecase.dart`

Formats:
- CSV (comma-separated)
- Excel (.xlsx using `excel` package)
- PDF (detailed report)

Exports include:
- Transaction history
- Designer earnings
- Top designs
- User metrics

### 8. Real-time Analytics Updates

Use Firestore snapshots:
```dart
FirebaseFirestore.instance
  .collection('analytics/admin/daily_metrics')
  .orderBy('date', descending: true)
  .limit(30)
  .snapshots()
  .listen((snapshot) {
    // Update chart data
  });
```

### 9. Analytics BLoC

**Path:** `lib/bloc/analytics/analytics_bloc.dart`

Events:
- `LoadKPIsEvent()`
- `LoadRevenueChartEvent(dateRange)`
- `LoadUserAcquisitionEvent(dateRange)`
- `ExportDataEvent(format, filters)`
- `LoadTopDesignsEvent(limit)`

States:
- `AnalyticsLoading`
- `AnalyticsLoaded(data)`
- `ExportInProgress`
- `ExportComplete(filePath)`
- `AnalyticsError`

### 10. Security

- Admin-only access (check role in BLoC)
- Don't expose individual user data in public reports
- Rate limit report generation
- Log analytics access for audit

### 11. Performance

- Cache daily metrics locally
- Batch calculate aggregations (Firebase Cloud Functions)
- Limit chart data to 30 days (show summary for older)
- Lazy load detailed reports

---

**Phase 1 MVP:** Basic KPI dashboard, revenue chart  
**Phase 2+:** Advanced analytics, custom reports

---

**Ready for admin insights!**
