import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

/// User settings: persistent theme mode, language switcher, app version.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const String _appVersion = '1.0.0';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

    return Scaffold(
      appBar: AppAppBar(
        title: strings.settings,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;
            final padding = isSmallScreen ? 12.0 : 20.0;

            return ListView(
              padding: EdgeInsets.all(padding),
              children: [
                _buildSectionTitle(strings.appearance),
                _buildThemeSection(),
                SizedBox(height: padding),
                _buildSectionTitle(strings.language),
                _buildLanguageSection(),
                SizedBox(height: padding),
                _buildSectionTitle(strings.appVersion),
                _buildVersionSection(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: AppTextStyles.labelMedium(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildThemeSection() {
    final strings = AppLocalization.strings;

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              _buildOptionTile(
                icon: Icons.light_mode_outlined,
                label: strings.lightMode,
                isSelected: themeMode == ThemeMode.light,
                onTap: () =>
                    context.read<ThemeCubit>().setMode(ThemeMode.light),
              ),
              const Divider(height: 1),
              _buildOptionTile(
                icon: Icons.dark_mode_outlined,
                label: strings.darkMode,
                isSelected: themeMode == ThemeMode.dark,
                onTap: () =>
                    context.read<ThemeCubit>().setMode(ThemeMode.dark),
              ),
              const Divider(height: 1),
              _buildOptionTile(
                icon: Icons.brightness_auto_outlined,
                label: strings.systemDefault,
                isSelected: themeMode == ThemeMode.system,
                onTap: () =>
                    context.read<ThemeCubit>().setMode(ThemeMode.system),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageSection() {
    final strings = AppLocalization.strings;
    final currentLocale = AppLocalization.getCurrentLocale();

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _buildOptionTile(
            icon: Icons.language_outlined,
            label: strings.languageEnglish,
            isSelected: currentLocale == 'en_US',
            onTap: () => _changeLocale('en_US'),
          ),
          const Divider(height: 1),
          _buildOptionTile(
            icon: Icons.translate_outlined,
            label: strings.languageHindi,
            isSelected: currentLocale == 'hi_IN',
            onTap: () => _changeLocale('hi_IN'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionSection() {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          Icons.info_outline,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
        title: Text(
          AppLocalization.strings.appName,
          style: AppTextStyles.bodyMedium(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          'v${SettingsScreen._appVersion}',
          style: AppTextStyles.labelMedium(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        size: 22,
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary, size: 20)
          : null,
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
