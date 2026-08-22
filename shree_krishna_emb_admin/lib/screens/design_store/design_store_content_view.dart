import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/categories_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/designs_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/core/auth/access_policy.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/categories_view.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/collections_view.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/designs_view.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/home_layout_view.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

/// Design Store content (no Scaffold) — embedded in the dashboard content area
/// like User Management / Settings. Tabs: Collections | Categories | Designs.
/// (Phase B adds a Home Layout tab.)
class DesignStoreContentView extends StatelessWidget {
  const DesignStoreContentView({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    // Home layout curation is platform-wide — admin only (D2).
    final authState = GetIt.instance<AdminAuthBloc>().state;
    final policy = AccessPolicy(
      authState is AdminAuthAuthenticated ? authState.role : 'admin',
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.instance<CollectionsCubit>()..load()),
        BlocProvider(create: (_) => GetIt.instance<CategoriesCubit>()..load()),
        BlocProvider(create: (_) => GetIt.instance<DesignsCubit>()..load()),
      ],
      child: DefaultTabController(
        length: policy.canEditHomeLayout ? 4 : 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                strings.designStore,
                style: AppTextStyles.headlineMedium(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TabBar(
              isScrollable: true,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              tabAlignment: TabAlignment.start,
              tabs: [
                if (policy.canEditHomeLayout) Tab(text: strings.homeLayout),
                Tab(text: strings.designs),
                Tab(text: strings.categories),
                Tab(text: strings.collections),
              ],
            ),
            Expanded(
              child: TabBarView(
                // Tabs change only via the tab bar — no horizontal swipe (it
                // conflicts with horizontal lists / drag-reorder inside tabs).
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  if (policy.canEditHomeLayout) const HomeLayoutView(),
                  const DesignsView(),
                  const CategoriesView(),
                  const CollectionsView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
