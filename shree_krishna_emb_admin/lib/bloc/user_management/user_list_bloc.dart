import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/user_list_repository.dart';
import 'user_list_event.dart';
import 'user_list_state.dart';

class UserListBloc extends Bloc<UserListEvent, UserListState> {
  final UserListRepository repository;

  /// Selectable page sizes for the user list.
  static const List<int> pageSizeOptions = [25, 50, 100];

  int _currentPage = 1;
  int _totalUsers = 0;
  String? _searchQuery;
  int _pageSize = 25;
  String? _roleFilter;

  /// Current page size (rows per page).
  int get pageSize => _pageSize;

  /// Current role filter (null = all roles).
  String? get roleFilter => _roleFilter;

  UserListBloc({required this.repository}) : super(const UserListInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<SearchUsersEvent>(_onSearchUsers);
    on<NextPageEvent>(_onNextPage);
    on<PreviousPageEvent>(_onPreviousPage);
    on<GoToPageEvent>(_onGoToPage);
    on<EditUserEvent>(_onEditUser);
    on<SuspendUserEvent>(_onSuspendUser);
    on<DeleteUserEvent>(_onDeleteUser);
    on<RefreshUsersEvent>(_onRefreshUsers);
    on<CreateUserEvent>(_onCreateUser);
    on<SendPasswordResetEvent>(_onSendPasswordReset);
    on<ChangePageSizeEvent>(_onChangePageSize);
    on<FilterByRoleEvent>(_onFilterByRole);
  }

  Future<void> _onFilterByRole(
    FilterByRoleEvent event,
    Emitter<UserListState> emit,
  ) async {
    _roleFilter = event.role;
    _currentPage = 1;
    emit(const UserListLoading());

    final countResult = await repository.getUserCount(
      searchQuery: _searchQuery,
      roleFilter: _roleFilter,
    );
    final count = countResult.fold(
      (failure) {
        emit(UserListError(failure.message));
        return 0;
      },
      (count) => count,
    );

    if (count == 0) {
      _totalUsers = 0;
      emit(UserListLoaded(
        users: const [],
        currentPage: 1,
        totalPages: 1,
        totalUsers: 0,
        searchQuery: _searchQuery,
      ));
      return;
    }

    _totalUsers = count;

    final result = await repository.getUsers(
      page: _currentPage,
      pageSize: pageSize,
      searchQuery: _searchQuery,
      roleFilter: _roleFilter,
    );
    result.fold(
      (failure) => emit(UserListError(failure.message)),
      (users) {
        final totalPages = (_totalUsers / pageSize).ceil();
        emit(UserListLoaded(
          users: users,
          currentPage: _currentPage,
          totalPages: totalPages,
          totalUsers: _totalUsers,
          searchQuery: _searchQuery,
        ));
      },
    );
  }

  Future<void> _onChangePageSize(
    ChangePageSizeEvent event,
    Emitter<UserListState> emit,
  ) async {
    if (event.pageSize == _pageSize) return;
    _pageSize = event.pageSize;
    _currentPage = 1;
    add(LoadUsersEvent());
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserListState> emit,
  ) async {
    emit(const UserListLoading());
    _currentPage = 1;
    _searchQuery = null;

    final countResult = await repository.getUserCount(
      roleFilter: _roleFilter,
      forceRefresh: event.forceRefresh,
    );

    final count = countResult.fold(
      (failure) {
        emit(UserListError(failure.message));
        return 0;
      },
      (count) => count,
    );

    if (count == 0) {
      _totalUsers = 0;
      emit(UserListLoaded(
        users: const [],
        currentPage: 1,
        totalPages: 1,
        totalUsers: 0,
        searchQuery: _searchQuery,
      ));
      return;
    }

    _totalUsers = count;

    final result = await repository.getUsers(
      page: _currentPage,
      pageSize: pageSize,
      searchQuery: _searchQuery,
      roleFilter: _roleFilter,
    );

    result.fold(
      (failure) => emit(UserListError(failure.message)),
      (users) {
        final totalPages = (_totalUsers / pageSize).ceil();
        emit(UserListLoaded(
          users: users,
          currentPage: _currentPage,
          totalPages: totalPages,
          totalUsers: _totalUsers,
          searchQuery: _searchQuery,
        ));
      },
    );
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<UserListState> emit,
  ) async {
    emit(const UserListLoading());
    _currentPage = 1;
    _searchQuery = event.query.isEmpty ? null : event.query;

    final countResult = await repository.getUserCount(
      searchQuery: _searchQuery,
      roleFilter: _roleFilter,
    );

    final count = countResult.fold(
      (failure) {
        emit(UserListError(failure.message));
        return 0;
      },
      (count) => count,
    );

    if (count == 0) {
      _totalUsers = 0;
      emit(UserListLoaded(
        users: const [],
        currentPage: 1,
        totalPages: 1,
        totalUsers: 0,
        searchQuery: _searchQuery,
      ));
      return;
    }

    _totalUsers = count;

    final result = await repository.getUsers(
      page: _currentPage,
      pageSize: pageSize,
      searchQuery: _searchQuery,
      roleFilter: _roleFilter,
    );

    result.fold(
      (failure) => emit(UserListError(failure.message)),
      (users) {
        final totalPages = _totalUsers > 0 ? (_totalUsers / pageSize).ceil() : 1;
        emit(UserListLoaded(
          users: users,
          currentPage: _currentPage,
          totalPages: totalPages,
          totalUsers: _totalUsers,
          searchQuery: _searchQuery,
        ));
      },
    );
  }

  Future<void> _onNextPage(
    NextPageEvent event,
    Emitter<UserListState> emit,
  ) async {
    if (state is UserListLoaded) {
      final currentState = state as UserListLoaded;
      if (_currentPage < currentState.totalPages) {
        _currentPage++;
        add(LoadUsersEvent());
      }
    }
  }

  Future<void> _onPreviousPage(
    PreviousPageEvent event,
    Emitter<UserListState> emit,
  ) async {
    if (_currentPage > 1) {
      _currentPage--;
      add(LoadUsersEvent());
    }
  }

  Future<void> _onGoToPage(
    GoToPageEvent event,
    Emitter<UserListState> emit,
  ) async {
    if (state is UserListLoaded) {
      final currentState = state as UserListLoaded;
      if (event.pageNumber >= 1 &&
          event.pageNumber <= currentState.totalPages) {
        _currentPage = event.pageNumber;
        add(LoadUsersEvent());
      }
    }
  }

  Future<void> _onEditUser(
    EditUserEvent event,
    Emitter<UserListState> emit,
  ) async {
    emit(const UserActionLoading('edit'));

    final result = await repository.updateUser(event.user);
    result.fold(
      (failure) {
        emit(UserActionError(failure.message));
        // Restore the list so the action loader doesn't stay stuck on error.
        add(RefreshUsersEvent());
      },
      (_) {
        emit(const UserActionSuccess('User updated successfully'));
        add(RefreshUsersEvent());
      },
    );
  }

  Future<void> _onSuspendUser(
    SuspendUserEvent event,
    Emitter<UserListState> emit,
  ) async {
    emit(const UserActionLoading('suspend'));

    final result = await repository.toggleUserStatus(
      event.userId,
      !event.suspend,
    );

    result.fold(
      (failure) {
        emit(UserActionError(failure.message));
        add(RefreshUsersEvent());
      },
      (_) {
        final message =
            event.suspend ? 'User suspended' : 'User activated';
        emit(UserActionSuccess(message));
        add(RefreshUsersEvent());
      },
    );
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserListState> emit,
  ) async {
    emit(const UserActionLoading('delete'));

    final result = await repository.deleteUser(event.userId);
    result.fold(
      (failure) {
        emit(UserActionError(failure.message));
        add(RefreshUsersEvent());
      },
      (_) {
        emit(const UserActionSuccess('User deleted successfully'));
        add(RefreshUsersEvent());
      },
    );
  }

  Future<void> _onRefreshUsers(
    RefreshUsersEvent event,
    Emitter<UserListState> emit,
  ) async {
    final result = await repository.getUsers(
      page: _currentPage,
      pageSize: pageSize,
      searchQuery: _searchQuery,
      roleFilter: _roleFilter,
    );

    result.fold(
      (failure) => emit(UserListError(failure.message)),
      (users) {
        final totalPages = _totalUsers > 0 ? (_totalUsers / pageSize).ceil() : 1;
        emit(UserListLoaded(
          users: users,
          currentPage: _currentPage,
          totalPages: totalPages,
          totalUsers: _totalUsers,
          searchQuery: _searchQuery,
        ));
      },
    );
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<UserListState> emit,
  ) async {
    emit(const UserActionLoading('create'));

    final result = await repository.createUser(
      name: event.name,
      email: event.email,
      password: event.password,
      phoneNumber: event.phoneNumber,
      role: event.role,
      photoUrl: event.photoUrl,
      storeName: event.storeName,
      storeImageUrl: event.storeImageUrl,
      storeDescription: event.storeDescription,
      isAuthorisedSeller: event.isAuthorisedSeller,
    );

    result.fold(
      (failure) {
        emit(UserActionError(failure.message));
        // Restore the list so the action loader doesn't stay stuck on error.
        add(LoadUsersEvent());
      },
      (_) {
        emit(const UserActionSuccess('User created successfully'));
        // Reload from page 1 so the new user (newest createdAt) is visible and
        // the total count is recomputed.
        add(LoadUsersEvent());
      },
    );
  }

  Future<void> _onSendPasswordReset(
    SendPasswordResetEvent event,
    Emitter<UserListState> emit,
  ) async {
    emit(const UserActionLoading('reset-password'));

    final result = await repository.sendPasswordReset(event.email);
    result.fold(
      (failure) {
        emit(UserActionError(failure.message));
        add(RefreshUsersEvent());
      },
      (_) {
        emit(const UserActionSuccess('Password reset email sent'));
        // Restore the list so the action loader doesn't stay stuck.
        add(RefreshUsersEvent());
      },
    );
  }
}
