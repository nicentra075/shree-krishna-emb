import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';

import '../../bloc/notifications/broadcast_cubit.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/responsive_snackbar.dart';
import '../../l10n/app_localization.dart';
import '../../l10n/locales/locale_base.dart';

/// Opens the "send broadcast" composer as a dialog. Two steps: compose
/// (title + message) then confirm (since this pushes to every user).
Future<void> showBroadcastComposer(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => BlocProvider<BroadcastCubit>(
      create: (_) => getIt<BroadcastCubit>(),
      child: const _BroadcastDialog(),
    ),
  );
}

class _BroadcastDialog extends StatefulWidget {
  const _BroadcastDialog();

  @override
  State<_BroadcastDialog> createState() => _BroadcastDialogState();
}

class _BroadcastDialogState extends State<_BroadcastDialog> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _confirming = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// Maps the cubit's internal error keys / raw exception text to a
  /// localized, admin-readable message.
  String _errorMessage(LocaleStrings s, String? error) {
    switch (error) {
      case 'invalid_title':
        return _title.text.trim().isEmpty
            ? s.broadcastTitleRequired
            : s.broadcastTitleTooLong;
      case 'invalid_body':
        return s.broadcastBodyRequired;
      default:
        return error ?? s.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<BroadcastCubit, BroadcastState>(
      listener: (context, state) {
        if (state.status == BroadcastStatus.sent) {
          Navigator.of(context).pop();
          ResponsiveSnackbar.showSuccess(
            '${s.broadcastSent} (${state.recipientCount})',
            context,
          );
        } else if (state.status == BroadcastStatus.error) {
          setState(() => _confirming = false);
          ResponsiveSnackbar.showError(
            _errorMessage(s, state.error),
            context,
          );
        }
      },
      builder: (context, state) {
        final sending = state.status == BroadcastStatus.sending;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            s.sendBroadcast,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _confirming
                ? _buildConfirmStep(s, colorScheme)
                : _buildComposeStep(s),
          ),
          actions: _confirming
              ? _confirmActions(context, s, sending)
              : _composeActions(context, s),
        );
      },
    );
  }

  Widget _buildComposeStep(LocaleStrings s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _title,
          label: s.broadcastTitle,
          hint: s.broadcastTitle,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _body,
          label: s.broadcastBody,
          hint: s.broadcastBody,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildConfirmStep(LocaleStrings s, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.broadcastConfirmMessage,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title.text.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _body.text.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _composeActions(BuildContext context, LocaleStrings s) {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(s.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AppButton(
        label: s.sendToAllUsers,
        onPressed: () {
          if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
            ResponsiveSnackbar.showError(
              _title.text.trim().isEmpty
                  ? s.broadcastTitleRequired
                  : s.broadcastBodyRequired,
              context,
            );
            return;
          }
          if (_title.text.trim().length > BroadcastCubit.titleMaxLength) {
            ResponsiveSnackbar.showError(s.broadcastTitleTooLong, context);
            return;
          }
          setState(() => _confirming = true);
        },
      ),
    ];
  }

  List<Widget> _confirmActions(
    BuildContext context,
    LocaleStrings s,
    bool sending,
  ) {
    return [
      TextButton(
        onPressed: sending ? null : () => setState(() => _confirming = false),
        child: Text(s.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AppButton(
        label: s.confirm,
        isLoading: sending,
        onPressed: () {
          context.read<BroadcastCubit>().send(
                _title.text.trim(),
                _body.text.trim(),
              );
        },
      ),
    ];
  }
}
