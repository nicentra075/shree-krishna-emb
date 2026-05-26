import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/user_list_repository.dart';
import 'user_list_event.dart';
import 'user_list_state.dart';

class UserListBloc extends Bloc<UserListEvent, UserListState> {
  final UserListRepository repository;
  static const int pageSize = 10;

  int _currentPage = 1;
  int _totalUsers = 0;
  String? _searchQuery;

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
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserListState> emit,
  ) async {
    emit(const UserListLoading());
    _currentPage = 1;
    _searchQuery = null;

    final countResult = await repository.getUserCount();
    countResult.fold(
      (failure) => emit(UserListError(failure.message)),
      (count) async {
        _totalUsers = count;
        final result = await repository.getUsers(
          page: _currentPage,
          pageSize: pageSize,
          searchQuery: _searchQuery,
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
    );

    countResult.fold(
      (failure) => emit(UserListError(failure.message)),
      (count) async {
        _totalUsers = count;
        final result = await repository.getUsers(
          page: _currentPage,
          pageSize: pageSize,
          searchQuery: _searchQuery,
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
      (failure) => emit(UserActionError(failure.message)),
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
      (failure) => emit(UserActionError(failure.message)),
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
      (failure) => emit(UserActionError(failure.message)),
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
}
