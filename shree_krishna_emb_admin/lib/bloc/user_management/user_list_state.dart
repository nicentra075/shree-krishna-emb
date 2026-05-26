import 'package:equatable/equatable.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';

abstract class UserListState extends Equatable {
  const UserListState();

  @override
  List<Object?> get props => [];
}

class UserListInitial extends UserListState {
  const UserListInitial();
}

class UserListLoading extends UserListState {
  const UserListLoading();
}

class UserListLoaded extends UserListState {
  final List<UserListItemModel> users;
  final int currentPage;
  final int totalPages;
  final int totalUsers;
  final String? searchQuery;

  const UserListLoaded({
    required this.users,
    required this.currentPage,
    required this.totalPages,
    required this.totalUsers,
    this.searchQuery,
  });

  @override
  List<Object?> get props =>
      [users, currentPage, totalPages, totalUsers, searchQuery];
}

class UserListError extends UserListState {
  final String message;

  const UserListError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserActionLoading extends UserListState {
  final String actionType; // 'edit', 'delete', 'suspend'

  const UserActionLoading(this.actionType);

  @override
  List<Object?> get props => [actionType];
}

class UserActionSuccess extends UserListState {
  final String message;

  const UserActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class UserActionError extends UserListState {
  final String message;

  const UserActionError(this.message);

  @override
  List<Object?> get props => [message];
}
