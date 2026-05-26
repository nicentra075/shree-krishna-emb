import 'package:equatable/equatable.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';

abstract class UserListEvent extends Equatable {
  const UserListEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends UserListEvent {
  const LoadUsersEvent();
}

class SearchUsersEvent extends UserListEvent {
  final String query;

  const SearchUsersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class NextPageEvent extends UserListEvent {
  const NextPageEvent();
}

class PreviousPageEvent extends UserListEvent {
  const PreviousPageEvent();
}

class GoToPageEvent extends UserListEvent {
  final int pageNumber;

  const GoToPageEvent(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

class EditUserEvent extends UserListEvent {
  final UserListItemModel user;

  const EditUserEvent(this.user);

  @override
  List<Object?> get props => [user];
}

class SuspendUserEvent extends UserListEvent {
  final String userId;
  final bool suspend;

  const SuspendUserEvent(this.userId, this.suspend);

  @override
  List<Object?> get props => [userId, suspend];
}

class DeleteUserEvent extends UserListEvent {
  final String userId;

  const DeleteUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class RefreshUsersEvent extends UserListEvent {
  const RefreshUsersEvent();
}

class CreateUserEvent extends UserListEvent {
  final String name;
  final String email;
  final String password;
  final String phoneNumber;
  final String role;

  const CreateUserEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.role,
  });

  @override
  List<Object?> get props => [name, email, password, phoneNumber, role];
}
