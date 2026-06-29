import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/payouts/payouts_cubit.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_payouts_datasource.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

/// Interim, READ-ONLY designer earnings owed. No money moves here — every row
/// is "Owed" until the wallet/payout Cloud Functions land.
class PayoutsContentView extends StatelessWidget {
  const PayoutsContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PayoutsCubit>(
      create: (_) => GetIt.instance<PayoutsCubit>()..load(),
      child: const _PayoutsBody(),
    );
  }
}

class _PayoutsBody extends StatelessWidget {
  const _PayoutsBody();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: BlocBuilder<PayoutsCubit, PayoutsState>(
        builder: (context, state) {
          final cubit = context.read<PayoutsCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.payouts,
                            style: AppTextStyles.headlineMedium(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.payoutsInterimNote,
                            style: AppTextStyles.bodySmall(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (state.status == PayoutsStatus.loaded &&
                        state.earnings.isNotEmpty)
                      _totalBadge(context, state.totalOwed, strings),
                  ],
                ),
              ),
              Expanded(
                child: _body(context, state, cubit, strings, colorScheme),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _totalBadge(BuildContext context, int total, dynamic strings) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            strings.totalOwed,
            style: AppTextStyles.labelSmall(color: colorScheme.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '₹$total',
            style: AppTextStyles.labelLarge(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    PayoutsState state,
    PayoutsCubit cubit,
    dynamic strings,
    ColorScheme colorScheme,
  ) {
    if (state.status == PayoutsStatus.loading ||
        state.status == PayoutsStatus.initial) {
      return const Center(child: AppLoader());
    }
    if (state.status == PayoutsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.error ?? strings.error,
              style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: strings.retry,
              variant: AppButtonVariant.secondary,
              onPressed: () => cubit.load(forceRefresh: true),
            ),
          ],
        ),
      );
    }
    if (state.earnings.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.account_balance_wallet_outlined,
          message: strings.noEarnings,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: state.earnings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _row(context, state.earnings[index], strings, colorScheme),
    );
  }

  Widget _row(
    BuildContext context,
    DesignerEarnings e,
    dynamic strings,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(
              Icons.person_outline,
              size: 18,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.designerName,
                  style: AppTextStyles.labelLarge(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${e.unitsSold} ${strings.unitsSold} · '
                  '${strings.grossSales}: ₹${e.grossSales}',
                  style: AppTextStyles.labelSmall(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${e.amountOwed}',
                style: AppTextStyles.labelLarge(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFA726).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  strings.owed,
                  style: AppTextStyles.labelSmall(
                    color: const Color(0xFFFFA726),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
