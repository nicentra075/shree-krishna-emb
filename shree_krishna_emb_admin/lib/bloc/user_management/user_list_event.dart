import 'package:equatable/equatable.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';

abstract class UserListEvent extends Equatable {
  const UserListEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends UserListEvent {
  /// When true, bypasses the datasource cache and re-reads from Firestore.
  final bool forceRefresh;

  const LoadUsersEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
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
  final String? photoUrl;
  final String? storeName;
  final String? storeImageUrl;
  final String? storeDescription;
  final bool isAuthorisedSeller;

  const CreateUserEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.role,
    this.photoUrl,
    this.storeName,
    this.storeImageUrl,
    this.storeDescription,
    this.isAuthorisedSeller = false,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    password,
    phoneNumber,
    role,
    photoUrl,
    storeName,
    storeImageUrl,
    storeDescription,
    isAuthorisedSeller,
  ];
}

class SendPasswordResetEvent extends UserListEvent {
  final String email;

  const SendPasswordResetEvent(this.email);

  @override
  List<Object?> get props => [email];
}

class ChangePageSizeEvent extends UserListEvent {
  final int pageSize;

  const ChangePageSizeEvent(this.pageSize);

  @override
  List<Object?> get props => [pageSize];
}

class FilterByRoleEvent extends UserListEvent {
  /// null = all roles.
  final String? role;

  const FilterByRoleEvent(this.role);

  @override
  List<Object?> get props => [role];
}
