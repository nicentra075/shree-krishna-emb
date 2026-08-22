import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_bloc.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/user_list_repository.dart';
import 'desktop_user_list_view.dart';
import 'mobile_user_list_view.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    return BlocProvider(
      create: (context) =>
          UserListBloc(repository: GetIt.instance<UserListRepository>()),
      child: isMobile
          ? const MobileUserListView()
          : const DesktopUserListView(),
    );
  }
}
