import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';

import '../../../bloc/notifications/broadcast_cubit.dart';
import '../../../core/utils/responsive_snackbar.dart';
import '../../../l10n/app_localization.dart';
import '../../../l10n/locales/locale_base.dart';

/// One suggested notification template: a short display title (used as the
/// chip label) plus the localized title/body to prefill into the composer.
class _BroadcastTemplate {
  final String Function(LocaleStrings) title;
  final String Function(LocaleStrings) body;

  const _BroadcastTemplate({required this.title, required this.body});
}

const List<_BroadcastTemplate> _templates = [
  _BroadcastTemplate(
    title: _tplNewCollectionTitle,
    body: _tplNewCollectionBody,
  ),
  _BroadcastTemplate(title: _tplSaleTitle, body: _tplSaleBody),
  _BroadcastTemplate(title: _tplFestivalTitle, body: _tplFestivalBody),
  _BroadcastTemplate(title: _tplRestockTitle, body: _tplRestockBody),
  _BroadcastTemplate(title: _tplFreeDesignTitle, body: _tplFreeDesignBody),
];

String _tplNewCollectionTitle(LocaleStrings s) => s.tplNewCollectionTitle;
String _tplNewCollectionBody(LocaleStrings s) => s.tplNewCollectionBody;
String _tplSaleTitle(LocaleStrings s) => s.tplSaleTitle;
String _tplSaleBody(LocaleStrings s) => s.tplSaleBody;
String _tplFestivalTitle(LocaleStrings s) => s.tplFestivalTitle;
String _tplFestivalBody(LocaleStrings s) => s.tplFestivalBody;
String _tplRestockTitle(LocaleStrings s) => s.tplRestockTitle;
String _tplRestockBody(LocaleStrings s) => s.tplRestockBody;
String _tplFreeDesignTitle(LocaleStrings s) => s.tplFreeDesignTitle;
String _tplFreeDesignBody(LocaleStrings s) => s.tplFreeDesignBody;

/// Inline "send a broadcast to all users" composer, rendered directly inside
/// the Notifications settings tab (below [NotificationSettingsForm]).
/// Replaces the old popup dialog so the admin can compose + pick a suggested
/// template without leaving the settings page.
class BroadcastComposerSection extends StatefulWidget {
  const BroadcastComposerSection({super.key});

  @override
  State<BroadcastComposerSection> createState() =>
      _BroadcastComposerSectionState();
}

class _BroadcastComposerSectionState extends State<BroadcastComposerSection> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<BroadcastCubit>(
      create: (_) => GetIt.instance<BroadcastCubit>(),
      child: const _ComposerBody(),
    );
  }
}

class _ComposerBody extends StatefulWidget {
  const _ComposerBody();

  @override
  State<_ComposerBody> createState() => _ComposerBodyState();
}

class _ComposerBodyState extends State<_ComposerBody> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _applyTemplate(_BroadcastTemplate template) {
    final s = AppLocalization.strings;
    setState(() {
      _titleController.text = template.title(s);
      _bodyController.text = template.body(s);
    });
  }

  /// Maps the cubit's internal error keys / raw exception text to a
  /// localized, admin-readable message.
  String _errorMessage(LocaleStrings s, String? error) {
    switch (error) {
      case 'invalid_title':
        return _titleController.text.trim().isEmpty
            ? s.broadcastTitleRequired
            : s.broadcastTitleTooLong;
      case 'invalid_body':
        return s.broadcastBodyRequired;
      default:
        return error ?? s.error;
    }
  }

  String? _titleValidator(String? value, LocaleStrings s) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return s.broadcastTitleRequired;
    if (trimmed.length > BroadcastCubit.titleMaxLength) {
      return s.broadcastTitleTooLong;
    }
    return null;
  }

  String? _bodyValidator(String? value, LocaleStrings s) {
    if ((value ?? '').trim().isEmpty) return s.broadcastBodyRequired;
    return null;
  }

  Future<void> _handleSend(BuildContext context, LocaleStrings s) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirmed = await AppDialog.showConfirm(
      context,
      title: s.confirmBroadcastTitle,
      message: s.confirmBroadcastBody,
      confirmLabel: s.send,
      cancelLabel: s.cancel,
    );
    if (confirmed != true || !context.mounted) return;

    context.read<BroadcastCubit>().send(
      _titleController.text.trim(),
      _bodyController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<BroadcastCubit, BroadcastState>(
      listener: (context, state) {
        if (state.status == BroadcastStatus.sent) {
          ResponsiveSnackbar.showSuccess(
            s.broadcastSentCount(state.recipientCount),
            context,
          );
          _titleController.clear();
          _bodyController.clear();
          _formKey.currentState?.reset();
          context.read<BroadcastCubit>().reset();
        } else if (state.status == BroadcastStatus.error) {
          ResponsiveSnackbar.showError(_errorMessage(s, state.error), context);
        }
      },
      builder: (context, state) {
        final sending = state.status == BroadcastStatus.sending;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.broadcastComposeHeading,
                  style: AppTextStyles.labelMedium(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  s.suggestedTemplates,
                  style: AppTextStyles.labelSmall(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final template in _templates)
                      AppChip(
                        label: template.title(s),
                        onTap: sending ? null : () => _applyTemplate(template),
                      ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _titleController,
                        label: s.broadcastTitle,
                        hint: s.broadcastTitle,
                        enabled: !sending,
                        validator: (value) => _titleValidator(value, s),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _bodyController,
                        label: s.broadcastBody,
                        hint: s.broadcastBody,
                        maxLines: 4,
                        enabled: !sending,
                        validator: (value) => _bodyValidator(value, s),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: s.sendToAllUsers,
                    isLoading: sending,
                    onPressed: sending ? () {} : () => _handleSend(context, s),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
