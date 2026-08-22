import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/settings/notification_settings_cubit.dart';
import 'package:shree_krishna_emb_admin/core/auth/access_policy.dart';
import 'package:shree_krishna_emb_admin/core/dev/dummy_data_seeder.dart';
import 'package:shree_krishna_emb_admin/core/di/service_locator.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/settings/widgets/broadcast_composer_section.dart';
import 'package:shree_krishna_emb_admin/screens/settings/widgets/notification_settings_form.dart';
import 'package:shree_krishna_emb_admin/screens/settings/widgets/payments_section.dart';

/// Settings CONTENT only (no Scaffold) so it can be embedded in the
/// dashboard's content area next to the sidebar, like User Management,
/// and also wrapped by AdminSettingsScreen for standalone navigation.
class SettingsContentView extends StatefulWidget {
  const SettingsContentView({super.key});

  static const String appVersion = '1.0.0';

  @override
  State<SettingsContentView> createState() => _SettingsContentViewState();
}

class _SettingsContentViewState extends State<SettingsContentView>
    with SingleTickerProviderStateMixin {
  static const int _notificationsTabIndex = 2;

  bool _seeding = false;
  late final TabController _tabController;

  /// Owned here (rather than by [NotificationSettingsForm]) so the edited
  /// config — and its dirty state — survives the admin switching tabs, and
  /// so this screen can guard against navigating away with unsaved edits.
  late final NotificationSettingsCubit _notificationCubit;

  int _previousTabIndex = 0;

  /// Guards against the tab-switch listener re-entering itself while we're
  /// programmatically snapping the controller back/forward from inside the
  /// unsaved-changes confirm dialog flow.
  bool _guardingTabSwitch = false;

  /// Designers only get the General tab (theme/language); platform tabs
  /// (Payments, Notifications, Seed) are admin-only (D2).
  AccessPolicy get _policy {
    final authState = GetIt.instance<AdminAuthBloc>().state;
    return AccessPolicy(
      authState is AdminAuthAuthenticated ? authState.role : 'admin',
    );
  }

  int get _tabCount {
    if (!_policy.canConfigurePlatform) return 1;
    // Demo-data seeder tab is a dev-only tool — hidden in release builds.
    return kDebugMode ? 4 : 3;
  }

  @override
  void initState() {
    super.initState();
    _notificationCubit = GetIt.instance<NotificationSettingsCubit>()..load();
    _tabController = TabController(length: _tabCount, vsync: this)
      ..addListener(_handleTabControllerChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationCubit.close();
    super.dispose();
  }

  void _handleTabControllerChange() {
    // Wait for the switch animation to settle before reacting.
    if (_tabController.indexIsChanging) return;

    final newIndex = _tabController.index;

    if (_guardingTabSwitch) {
      // We're the ones driving this index change (from within
      // _guardTabSwitch) — just let the content rebuild.
      setState(() {});
      return;
    }

    if (_previousTabIndex == _notificationsTabIndex &&
        newIndex != _notificationsTabIndex &&
        _notificationCubit.state.hasUnsavedChanges) {
      _guardTabSwitch(newIndex);
      return;
    }

    _previousTabIndex = newIndex;
    setState(() {});
  }

  /// Called when the admin switches away from the Notifications tab while
  /// it has unsaved edits. Confirms whether to discard them (allowing the
  /// switch) or keep editing (snapping the tab bar back to Notifications).
  Future<void> _guardTabSwitch(int attemptedIndex) async {
    _guardingTabSwitch = true;
    final strings = AppLocalization.strings;

    final discard = await AppDialog.showConfirm(
      context,
      title: strings.discardChanges,
      message: strings.discardChangesBody,
      confirmLabel: strings.discard,
      cancelLabel: strings.keepEditing,
      isDestructive: true,
    );

    if (!mounted) {
      _guardingTabSwitch = false;
      return;
    }

    if (discard == true) {
      _notificationCubit.discardChanges();
      _previousTabIndex = attemptedIndex;
      _tabController.index = attemptedIndex;
    } else {
      _previousTabIndex = _notificationsTabIndex;
      _tabController.index = _notificationsTabIndex;
    }

    _guardingTabSwitch = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 480;
              final padding = isSmallScreen ? 12.0 : 24.0;

              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.settings,
                      style: AppTextStyles.headlineMedium(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    _buildTabBar(strings, colorScheme),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    _buildTabContent(isSmallScreen, strings),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(dynamic strings, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.labelMedium(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.labelMedium(),
        tabs: [
          Tab(text: strings.settingsTabGeneral),
          if (_policy.canConfigurePlatform) ...[
            Tab(text: strings.settingsTabPayments),
            Tab(text: strings.settingsTabNotifications),
            if (kDebugMode) Tab(text: strings.settingsTabSeed),
          ],
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isSmallScreen, dynamic strings) {
    switch (_tabController.index) {
      case 1:
        return _buildSectionCard(
          icon: Icons.payment_outlined,
          title: strings.payments,
          child: const PaymentsSection(),
        );
      case 2:
        return _buildSectionCard(
          icon: Icons.notifications_outlined,
          title: strings.settingsTabNotifications,
          child: BlocProvider<NotificationSettingsCubit>.value(
            value: _notificationCubit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NotificationSettingsForm(),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const BroadcastComposerSection(),
              ],
            ),
          ),
        );
      case 3:
        return _buildSectionCard(
          icon: Icons.science_outlined,
          title: strings.demoData,
          child: _buildDemoDataControls(),
        );
      case 0:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              icon: Icons.palette_outlined,
              title: strings.appearance,
              child: _buildThemeSelector(isSmallScreen),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildSectionCard(
              icon: Icons.language_outlined,
              title: strings.language,
              child: _buildLanguageSelector(),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildAboutCard(),
          ],
        );
    }
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelMedium(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildThemeSelector(bool isSmallScreen) {
    final strings = AppLocalization.strings;

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final options = [
          (ThemeMode.light, Icons.light_mode_outlined, strings.lightMode),
          (ThemeMode.dark, Icons.dark_mode_outlined, strings.darkMode),
          (
            ThemeMode.system,
            Icons.brightness_auto_outlined,
            strings.systemDefault,
          ),
        ];

        final cards = options.map((option) {
          final (mode, icon, label) = option;
          return _buildThemeModeCard(
            mode: mode,
            icon: icon,
            label: label,
            isSelected: themeMode == mode,
          );
        }).toList();

        if (isSmallScreen) {
          return Column(
            children: [
              for (final card in cards) ...[
                SizedBox(width: double.infinity, child: card),
                if (card != cards.last) const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (final card in cards) ...[
              Expanded(child: card),
              if (card != cards.last) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildThemeModeCard({
    required ThemeMode mode,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.read<ThemeCubit>().setMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.labelSmall(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final strings = AppLocalization.strings;
    final currentLocale = AppLocalization.getCurrentLocale();

    return Column(
      children: [
        _buildLanguageTile(
          initial: 'A',
          label: strings.languageEnglish,
          isSelected: currentLocale == 'en_US',
          onTap: () => _changeLocale('en_US'),
        ),
        const SizedBox(height: 8),
        _buildLanguageTile(
          initial: 'अ',
          label: strings.languageHindi,
          isSelected: currentLocale == 'hi_IN',
          onTap: () => _changeLocale('hi_IN'),
        ),
      ],
    );
  }

  Widget _buildLanguageTile({
    required String initial,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  initial,
                  style: AppTextStyles.labelMedium(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium(
                    color: colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppLocalization.strings;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.spa, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              strings.appName,
              style: AppTextStyles.bodyMedium(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'v${SettingsContentView.appVersion}',
              style: AppTextStyles.labelSmall(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeLocale(String locale) async {
    if (locale == AppLocalization.getCurrentLocale()) return;
    await AppLocalization.setLocale(locale);
    if (!mounted) return;
    setState(() {});
    ResponsiveSnackbar.showSuccess(
      AppLocalization.strings.languageChanged,
      context,
    );
  }

  // ---------------- Demo data ----------------
  Widget _buildDemoDataControls() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seeds demo accounts, 3 collections (with categories + designs) and a '
          'home layout so the user app has content. Idempotent — safe to re-run.',
          style: AppTextStyles.bodySmall(color: colorScheme.onSurfaceVariant),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            AppButton(
              label: 'Generate',
              leadingIcon: Icons.add_circle_outline,
              isLoading: _seeding,
              onPressed: _seeding
                  ? () {}
                  : () => _confirmAndRun(isClear: false),
            ),
            const SizedBox(width: 12),
            AppButton(
              label: 'Remove',
              leadingIcon: Icons.delete_outline,
              variant: AppButtonVariant.secondary,
              onPressed: _seeding ? () {} : () => _confirmAndRun(isClear: true),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmAndRun({required bool isClear}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isClear ? 'Remove demo data?' : 'Generate demo data?'),
        content: Text(
          isClear
              ? 'Deletes the seeded collections, categories, designs, home layout '
                    'and demo profile docs. (The demo Auth accounts must be removed '
                    'from the Firebase console manually.)'
              : 'Creates demo accounts, collections/categories/designs and a home '
                    'layout in Firebase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalization.strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalization.strings.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _seeding = true);
    final seeder = DummyDataSeeder(firestore: getIt<FirebaseFirestore>());
    try {
      void onProgress(String msg) {
        if (mounted) ResponsiveSnackbar.showInfo(msg, context);
      }

      if (isClear) {
        await seeder.clear(onProgress: onProgress);
      } else {
        await seeder.seed(onProgress: onProgress);
      }
      if (!mounted) return;
      ResponsiveSnackbar.showSuccess(
        isClear ? 'Demo data removed' : 'Demo data generated',
        context,
      );
    } catch (e) {
      if (mounted) {
        ResponsiveSnackbar.showError('Failed: $e', context);
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }
}
