# User Management Feature Design

> **For agentic workers:** This design has been approved. Use superpowers:writing-plans to create the implementation plan.

**Goal:** Enable admins to view, search, and manage all users in the system through a dedicated User Management panel with table view, pagination, and inline actions.

**Architecture:** BLoC-driven architecture with clean separation of layers. Firebase datasource provides paginated user queries. User list BLoC manages search state, pagination, and user actions. Table UI displays results with inline action buttons.

**Tech Stack:** Flutter, BLoC pattern, Firebase Firestore, clean architecture

---

## Feature Specification

### 1. User Management Screen

**Location:** Main content panel when "User Management" is clicked in sidebar
**Accessibility:** Admin-only feature (enforced at Firebase rules level)

#### Screen Structure

**Header**
- Title: "User Management"
- Search field with placeholder "Search by name or email..."
- Live search as user types (real-time filtering)
- Results counter: "Showing X of Y users"

**Table View**
Columns:
| Column | Width | Content |
|--------|-------|---------|
| Name | 20% | User's full name |
| Email | 30% | User's email address |
| Role | 15% | Admin / User / Designer (or custom roles) |
| Status | 15% | Badge: Active (green) or Suspended (red) |
| Actions | 20% | Action buttons: View, Edit, Suspend/Activate, Delete |

**Pagination**
- Previous button (disabled on page 1)
- Page indicators: "1 2 3 4 5 ... X" with current page highlighted
- Next button (disabled on last page)
- Items per page: 10 (configurable, default)
- Page info: "Page 1 of 5"

---

### 2. User Data Model

Each user in the table displays from Firestore:

```dart
class UserListItem {
  final String id;              // Firebase UID
  final String name;            // User's full name
  final String email;           // User's email
  final String role;            // 'admin', 'user', 'designer'
  final bool isActive;          // true=Active, false=Suspended
  final DateTime createdAt;     // Account creation timestamp
}
```

**Data Source:** Firebase `users` collection
- Query: `where('isActive', whereIn: [true, false])` (all users)
- Order by: `createdAt` descending (newest first)
- Limit: 10 per page
- Search: Client-side filtering on `name` and `email` fields

---

### 3. Search Functionality

**Behavior:**
- User types in search field → filter displayed list by name OR email
- Search is case-insensitive
- Updates in real-time (no search button needed)
- Resets pagination to page 1 when search term changes
- Empty search shows all users

**Implementation:**
- Search happens on already-fetched page data initially
- For larger datasets, future optimization: server-side search via Firestore query

---

### 4. Pagination

**Page Size:** 10 users per page
**Navigation:**
- Previous/Next buttons
- Direct page number selection (1 2 3 4 5...)
- Current page highlighted

**Behavior:**
- Load next page only when user clicks pagination button
- Maintain search filter across page changes
- Show appropriate message if no results match search

---

### 5. User Actions

#### 5.1 View Details
- Opens modal/bottom sheet
- Shows full user profile: name, email, role, status, created date, last login
- Read-only display
- Close button to dismiss

#### 5.2 Edit User
- Opens modal with form fields
- Editable fields: name, email, role
- Save button (updates Firestore)
- Cancel button
- Success notification on save
- Error handling for validation/Firebase errors

#### 5.3 Suspend/Activate
- Toggle button in Actions column
- "Suspend" for active users, "Activate" for suspended users
- Click → updates `isActive` field in Firestore immediately
- Success toast: "User suspended" or "User activated"
- Button state updates immediately in table

#### 5.4 Delete
- Delete button in Actions column
- Opens confirmation dialog: "Are you sure you want to delete this user? This action cannot be undone."
- Confirm/Cancel buttons
- On confirm: removes user document from Firestore
- Success toast: "User deleted successfully"
- Refreshes table to remove deleted user

---

### 6. Error Handling

**Network Errors:**
- Show error state in table: "Failed to load users. Please check your connection."
- Retry button to reload

**Firebase Errors:**
- Action fails: Show error toast "Failed to [action]. Please try again."
- Log error for debugging
- Table state reverts to previous state

**Empty State:**
- No users found: "No users found"
- Search with no results: "No users match your search"
- With suggestion to refine search

---

### 7. BLoC State Management

**Events:**
- `LoadUsersEvent` - Load first page of users
- `SearchUsersEvent(String query)` - Filter by name/email
- `NextPageEvent` - Load next page
- `PreviousPageEvent` - Go to previous page
- `GoToPageEvent(int pageNumber)` - Jump to specific page
- `EditUserEvent(UserListItem updatedUser)` - Update user
- `SuspendUserEvent(String userId)` - Toggle suspend status
- `DeleteUserEvent(String userId)` - Delete user
- `RefreshUsersEvent` - Reload current page

**States:**
- `UserListInitial` - Initial state
- `UserListLoading` - Loading users
- `UserListLoaded` - Users loaded successfully
- `UserListError(String message)` - Error occurred
- `UserActionLoading` - Processing user action (edit/delete/suspend)
- `UserActionSuccess(String message)` - Action completed
- `UserActionError(String message)` - Action failed

---

### 8. Architecture Layers

**Domain Layer:**
- `UserListItem` entity
- `UserListRepository` abstract interface

**Data Layer:**
- `FirebaseUserListDataSource` - Firestore queries with pagination
- `UserListRepositoryImpl` - Implements repository interface
- Handles pagination logic, search filtering

**Presentation Layer:**
- `UserManagementScreen` - Main UI screen
- `UserListBloc` - State management
- `UserListTable` - Table widget
- `UserActionsMenu` - Action buttons widget
- `UserEditDialog` - Edit user form
- `UserDetailsModal` - View user details

---

### 9. Firestore Queries

**Fetch users with pagination:**
```
users collection
  .orderBy('createdAt', descending: true)
  .limit(10)
  .get()
```

**For page N (offset pagination):**
```
users collection
  .orderBy('createdAt', descending: true)
  .startAfter([lastUserFromPreviousPage.createdAt])
  .limit(10)
  .get()
```

---

### 10. Testing Strategy

- Unit tests for UserListRepository pagination logic
- Unit tests for search filtering
- BLoC tests for state transitions
- Widget tests for table rendering
- Integration tests with Firebase Emulator

---

### 11. Security Considerations

- All user operations require admin authentication (verified at datasource level)
- Firebase security rules restrict user list access to admin role only
- Delete/edit operations log admin action for audit trail (future enhancement)
- Sensitive data (passwords, tokens) never displayed in table

---

### 12. Success Criteria

✅ Admins can view paginated list of users (10 per page)
✅ Search filters users by name or email in real-time
✅ Each user shows: name, email, role, status
✅ View Details opens modal with full profile
✅ Edit User updates user information
✅ Suspend/Activate toggles user active status
✅ Delete removes user from system
✅ All actions show success/error notifications
✅ Table maintains search filter across page navigation
✅ Error states display helpful messages
✅ Firebase Firestore integration complete
