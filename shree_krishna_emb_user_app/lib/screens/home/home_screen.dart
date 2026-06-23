import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_event.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';
import 'package:shree_krishna_emb/bloc/home_feed/home_feed_cubit.dart';
import 'package:shree_krishna_emb/bloc/wishlist/wishlist_cubit.dart';
import 'package:shree_krishna_emb/core/constants/app_constants.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/screens/home/widgets/home_shimmer.dart';
import 'package:shree_krishna_emb/screens/home/widgets/section_renderer.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeVerifyAccountStatus();
      // Load the signed-in user's favorites for app-wide heart state.
      getIt<WishlistCubit>().load();
    });
  }

  /// Re-validates the signed-in user's account status at most once per calendar
  /// day. If suspended, AuthBloc emits [AuthSuspended] and the listener signs
  /// the user out and routes to login.
  Future<void> _maybeVerifyAccountStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final lastChecked =
        prefs.getString(AppConstants.prefKeyLastStatusCheckDate);
    if (lastChecked == today) return;
    await prefs.setString(AppConstants.prefKeyLastStatusCheckDate, today);
    getIt<AuthBloc>().add(const VerifyAccountStatusEvent());
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthSuspended) {
      AppSnackbar.showError(AppLocalization.strings.accountSuspendedMessage);
      AppRoutes.navigateToLogin(context);
    }
  }

  /// Routes a section target (`design:<id>`, `collection:<id>`, `sellers`, …)
  /// to the matching screen.
  void _handleNavigate(BuildContext context, String? target) {
    AppRoutes.handleTarget(context, target);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: getIt<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: _onAuthStateChanged,
        child: BlocProvider<HomeFeedCubit>(
          create: (_) => getIt<HomeFeedCubit>()..load(),
          child: _HomeFeedBody(onNavigate: _handleNavigate),
        ),
      ),
    );
  }
}

class _HomeFeedBody extends StatelessWidget {
  final void Function(BuildContext, String?) onNavigate;
  const _HomeFeedBody({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryLight,
      onRefresh: () => context.read<HomeFeedCubit>().refresh(),
      child: BlocBuilder<HomeFeedCubit, HomeFeedState>(
        builder: (context, state) {
          if (state.status == HomeFeedStatus.loading ||
              state.status == HomeFeedStatus.initial) {
            return const HomeShimmer();
          }
          if (state.status == HomeFeedStatus.error &&
              state.feed.sections.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 160),
                Center(
                  child: Column(
                    children: [
                      Text(state.error ?? AppLocalization.strings.error,
                          style: AppTextStyles.bodyMedium()),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.read<HomeFeedCubit>().refresh(),
                        child: Text(AppLocalization.strings.retry),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          final sections = state.feed.sections;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            itemCount: sections.length,
            itemBuilder: (context, i) => SectionRenderer(
              section: sections[i],
              onNavigate: (target) => onNavigate(context, target),
              onViewAll: (target, title) {
                if (target == null || target.isEmpty) return;
                AppRoutes.navigateToViewAll(context, target, title: title);
              },
            ),
          );
        },
      ),
    );
  }
}
