import 'package:get_it/get_it.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';

/// The signed-in staff member's [AccessPolicy], resolved from the session
/// bloc. Falls back to admin only pre-auth (login screens don't gate on it).
AccessPolicy currentAccessPolicy() {
  final authState = GetIt.instance<AdminAuthBloc>().state;
  return AccessPolicy(
    authState is AdminAuthAuthenticated ? authState.role : 'admin',
  );
}

/// Role-based capability map for the admin panel (Phase 1 decision D2).
///
/// Pure Dart — safe for the presentation layer. The server enforces the same
/// boundaries via firestore.rules / storage.rules; this only decides what the
/// UI shows.
class AccessPolicy {
  final String role;

  const AccessPolicy(this.role);

  bool get isAdmin => role == 'admin';

  bool get isDesigner => role == 'designer';

  /// Sees every document (designs, orders, payouts, reports); designers are
  /// scoped to their own (`authorId` / `ownerIds`).
  bool get canSeeAllData => isAdmin;

  bool get canManageUsers => isAdmin;

  bool get canEditHomeLayout => isAdmin;

  bool get canConfigurePlatform => isAdmin;

  bool get canBroadcast => isAdmin;

  bool get canInitiateRefunds => isAdmin;

  /// Designers can CREATE categories/collections but not edit/delete the
  /// shared taxonomy (mirrors firestore.rules).
  bool get canMutateTaxonomy => isAdmin;

  /// Whether catalog queries must be filtered to the signed-in author.
  bool get isOwnerScoped => isDesigner;
}
