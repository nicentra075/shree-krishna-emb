# Three-Tab Bottom Navigation with Unified Role-Based Work Screen - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a three-tab bottom navigation (Home, Work, Account) with a unified Work screen that conditionally shows vendor dashboard or buyer purchases based on user role.

**Architecture:** The Work tab uses a single unified `WorkScreen` that detects the user's role from Firestore and conditionally renders vendor project listings (with Open/In Progress/Completed filters) OR buyer order history (with Pending/Delivered filters). The MainScreen is refactored to show only 3 bottom nav items instead of 5. HomeScreen and AccountScreen are updated with designs from the Stitch project. All screens use AppTheme colors and design system components.

**Tech Stack:** Flutter/BLoC, Firestore, Clean Architecture, AppTheme (Royal Saffron #ff9933 + Deep Blue #4059aa), shree_krishna_design_system, AppLocalization for all strings.

---

## File Structure

**New Files:**
- `lib/screens/work/work_screen.dart` - Unified work tab with role-based content
- `lib/bloc/work/work_event.dart` - Work tab events
- `lib/bloc/work/work_state.dart` - Work tab states
- `lib/bloc/work/work_bloc.dart` - Work tab BLoC

**Modified Files:**
- `lib/screens/main/main_screen.dart` - Reduce to 3 nav items, hide Search/Messages/Wishlist
- `lib/screens/home/home_screen.dart` - Update with Stitch design
- `lib/screens/profile/profile_screen.dart` - Update with Stitch design

---

## Task Breakdown

### Task 1: Create Work BLoC (Events & States)

**Files:**
- Create: `lib/bloc/work/work_event.dart`
- Create: `lib/bloc/work/work_state.dart`

- [ ] **Step 1: Create work_event.dart with events**

```dart
// lib/bloc/work/work_event.dart
import 'package:equatable/equatable.dart';

abstract class WorkEvent extends Equatable {
  const WorkEvent();

  @override
  List<Object?> get props => [];
}

class InitializeWorkEvent extends WorkEvent {
  const InitializeWorkEvent();
}

class FilterVendorWorkEvent extends WorkEvent {
  final String filter; // 'all', 'open', 'inProgress', 'completed'

  const FilterVendorWorkEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

class FilterBuyerOrdersEvent extends WorkEvent {
  final String filter; // 'all', 'pending', 'delivered'

  const FilterBuyerOrdersEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

class RefreshWorkDataEvent extends WorkEvent {
  const RefreshWorkDataEvent();
}
```

- [ ] **Step 2: Create work_state.dart with states**

```dart
// lib/bloc/work/work_state.dart
import 'package:equatable/equatable.dart';

abstract class WorkState extends Equatable {
  const WorkState();

  @override
  List<Object?> get props => [];
}

class WorkInitial extends WorkState {
  const WorkInitial();
}

class WorkLoading extends WorkState {
  const WorkLoading();
}

class WorkLoaded extends WorkState {
  final String userRole; // 'vendor' or 'buyer'
  final List<dynamic> vendorProjects; // List<WorkProject> if vendor
  final List<dynamic> buyerOrders; // List<Order> if buyer
  final String vendorFilter; // 'all', 'open', 'inProgress', 'completed'
  final String buyerFilter; // 'all', 'pending', 'delivered'

  const WorkLoaded({
    required this.userRole,
    required this.vendorProjects,
    required this.buyerOrders,
    required this.vendorFilter,
    required this.buyerFilter,
  });

  @override
  List<Object?> get props => [
    userRole,
    vendorProjects,
    buyerOrders,
    vendorFilter,
    buyerFilter,
  ];
}

class WorkError extends WorkState {
  final String message;

  const WorkError(this.message);

  @override
  List<Object?> get props => [message];
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/bloc/work/work_event.dart lib/bloc/work/work_state.dart
git commit -m "feat: add work bloc events and states"
```

---

### Task 2: Create Work BLoC Implementation

**Files:**
- Create: `lib/bloc/work/work_bloc.dart`

- [ ] **Step 1: Create work_bloc.dart**

```dart
// lib/bloc/work/work_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'work_event.dart';
import 'work_state.dart';

class WorkBloc extends Bloc<WorkEvent, WorkState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  WorkBloc() : super(const WorkInitial()) {
    on<InitializeWorkEvent>(_onInitialize);
    on<FilterVendorWorkEvent>(_onFilterVendorWork);
    on<FilterBuyerOrdersEvent>(_onFilterBuyerOrders);
    on<RefreshWorkDataEvent>(_onRefreshData);
  }

  Future<void> _onInitialize(
    InitializeWorkEvent event,
    Emitter<WorkState> emit,
  ) async {
    emit(const WorkLoading());
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        emit(const WorkError('User not authenticated'));
        return;
      }

      // Fetch user role from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userRole = userDoc.data()?['role'] ?? 'buyer'; // Default to buyer

      // Fetch data based on role
      final vendorProjects = userRole == 'vendor'
          ? await _fetchVendorProjects(userId)
          : <dynamic>[];
      
      final buyerOrders = userRole == 'buyer'
          ? await _fetchBuyerOrders(userId)
          : <dynamic>[];

      emit(WorkLoaded(
        userRole: userRole,
        vendorProjects: vendorProjects,
        buyerOrders: buyerOrders,
        vendorFilter: 'all',
        buyerFilter: 'all',
      ));
    } catch (e) {
      emit(WorkError('Failed to load work data: ${e.toString()}'));
    }
  }

  Future<void> _onFilterVendorWork(
    FilterVendorWorkEvent event,
    Emitter<WorkState> emit,
  ) async {
    if (state is! WorkLoaded) return;
    final currentState = state as WorkLoaded;

    emit(WorkLoaded(
      userRole: currentState.userRole,
      vendorProjects: currentState.vendorProjects,
      buyerOrders: currentState.buyerOrders,
      vendorFilter: event.filter,
      buyerFilter: currentState.buyerFilter,
    ));
  }

  Future<void> _onFilterBuyerOrders(
    FilterBuyerOrdersEvent event,
    Emitter<WorkState> emit,
  ) async {
    if (state is! WorkLoaded) return;
    final currentState = state as WorkLoaded;

    emit(WorkLoaded(
      userRole: currentState.userRole,
      vendorProjects: currentState.vendorProjects,
      buyerOrders: currentState.buyerOrders,
      vendorFilter: currentState.vendorFilter,
      buyerFilter: event.filter,
    ));
  }

  Future<void> _onRefreshData(
    RefreshWorkDataEvent event,
    Emitter<WorkState> emit,
  ) async {
    add(const InitializeWorkEvent());
  }

  Future<List<dynamic>> _fetchVendorProjects(String userId) async {
    // TODO: Fetch from Firestore based on actual schema
    return [];
  }

  Future<List<dynamic>> _fetchBuyerOrders(String userId) async {
    // TODO: Fetch from Firestore based on actual schema
    return [];
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/bloc/work/work_bloc.dart
git commit -m "feat: implement work bloc with role-based logic"
```

---

### Task 3: Create Unified Work Screen

**Files:**
- Create: `lib/screens/work/work_screen.dart`

**Description:** Create unified WorkScreen with role-based vendor/buyer sections. Show filter tabs (All/Open/In Progress/Completed for vendors, All/Pending/Delivered for buyers). Display empty states when no data. Use design system components only.

---

### Task 4: Update MainScreen to Show 3 Bottom Nav Items

**Files:**
- Modify: `lib/screens/main/main_screen.dart`

**Description:** Refactor bottom navigation from 5 items (Home, Search, Messages, Wishlist, Profile) to 3 items (Home, Work, Account). Update `_buildCurrentScreen()` to show WorkScreen (wrapped in WorkBloc provider) for tab 1. Update `_buildAppBar()` to hide app bar when `_selectedBottomNav == 2` (Account). Add imports for WorkScreen and WorkBloc.

---

### Task 5: Update HomeScreen with Stitch Design

**Files:**
- Modify: `lib/screens/home/home_screen.dart`

**Description:** Update HomeScreen layout to match Stitch design: Hero banner (New Arrival 2024), Authorized Sellers section, Trending Designs, Saree Designs, Explore Collections (4-item grid), Recently Viewed cards. Use AppTheme colors and design system components. All text from AppLocalization.

---

### Task 6: Update ProfileScreen with Stitch Design

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`

**Description:** Update ProfileScreen layout to match Stitch Account Profile: User header with avatar and info, Wallet section with balance and add funds button, Gold membership status, Studio management (My Work / My Selling Products), Settings section (Notifications, Dark Mode, Switch to Designer), Support section (WhatsApp, Contact Us, About Us, Privacy Policy, Terms). All text from AppLocalization.

---

### Task 7: Test Navigation & Role-Based Work Screen

**Files:**
- Test: Manual verification

**Description:** Run app and verify: (1) Bottom nav shows 3 items, (2) Home tab shows all Stitch sections, (3) Work tab shows loading then role-specific content (buyer orders or vendor projects), (4) Account tab shows profile with all sections, (5) All text is localized, (6) Pull-to-refresh works on Work tab, (7) Filter tabs work on Work tab.

---
