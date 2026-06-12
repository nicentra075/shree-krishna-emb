import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

/// Settings CONTENT only (no Scaffold) so it can be embedded in the
/// dashboard's content area next to the sidebar, like User Management,
/// and also wrapped by AdminSettingsScreen for standalone navigation.
class SettingsContentView extends StatefulWidget {
  const SettingsContentView({super.key});

  static const String appVersion = '1.0.0';

  @override
  State<SettingsContentView> createState() => _SettingsContentViewState();
}

class _SettingsContentViewState extends State<SettingsContentView> {
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

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
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
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
                ),
              );
            },
          ),
        ),
      ),
    );
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
          (ThemeMode.system, Icons.brightness_auto_outlined, strings.systemDefault),
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
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
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
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
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
    AppSnackbar.showSuccess(AppLocalization.strings.languageChanged);
  }
}
