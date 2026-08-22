import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/purchases/purchases_cubit.dart';
import 'package:shree_krishna_emb/bloc/suggested_designs/suggested_designs_cubit.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';
import 'package:shree_krishna_emb/screens/catalog/design_detail_screen.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/screens/purchases/orders_tab.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';

/// Standalone purchases screen (pushed from the profile). Wraps the shared
/// [MyPurchasesContent] in a Scaffold with its own app bar.
class MyPurchasesScreen extends StatelessWidget {
  const MyPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppAppBar(
        title: strings.myPurchases,
        onBack: () => Navigator.pop(context),
      ),
      body: const MyPurchasesContent(),
    );
  }
}

/// Shows the user's owned designs plus a "Suggested for you" row of designs
/// drawn from a random category so they can keep discovering and buying.
///
/// Scaffold-less so it can be embedded both as a standalone screen and as a
/// tab inside the main shell's existing app bar.
class MyPurchasesContent extends StatefulWidget {
  /// Called by the empty-state "Browse Designs" button. When null (e.g. opened
  /// standalone from the profile) the button is hidden.
  final VoidCallback? onBrowse;

  const MyPurchasesContent({super.key, this.onBrowse});

  @override
  State<MyPurchasesContent> createState() => _MyPurchasesContentState();
}

class _MyPurchasesContentState extends State<MyPurchasesContent> {
  @override
  void initState() {
    super.initState();
    // Ensure latest ownership when opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchasesCubit>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            labelStyle: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: strings.designsTab),
              Tab(text: strings.orders),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_designsTab(context), const OrdersTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _designsTab(BuildContext context) {
    return BlocProvider<SuggestedDesignsCubit>(
      create: (_) => getIt<SuggestedDesignsCubit>()..load(),
      child: BlocBuilder<PurchasesCubit, PurchasesState>(
        builder: (context, state) {
          if (state.status == PurchasesStatus.loading &&
              state.purchases.isEmpty) {
            return const Center(child: AppLoader());
          }

          final purchases = state.purchases;
          final crossAxisCount = MediaQuery.of(context).size.width >= 600
              ? 3
              : 2;

          return RefreshIndicator(
            onRefresh: () async {
              final purchasesCubit = context.read<PurchasesCubit>();
              final suggestedCubit = context.read<SuggestedDesignsCubit>();
              await purchasesCubit.refresh();
              await suggestedCubit.load();
            },
            child: CustomScrollView(
              slivers: [
                if (purchases.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyPurchases(onBrowse: widget.onBrowse),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _PurchaseCard(purchase: purchases[i]),
                        childCount: purchases.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: _SuggestedDesigns()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Empty state shown when the user has not bought anything yet: friendly copy
/// plus an optional CTA to go browse the catalog.
class _EmptyPurchases extends StatelessWidget {
  final VoidCallback? onBrowse;
  const _EmptyPurchases({this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppTheme.primaryLight.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            strings.noPurchasesYet,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headlineMedium(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            strings.noPurchasesMessage,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (onBrowse != null) ...[
            const SizedBox(height: 24),
            AppButton(
              label: strings.browseDesigns,
              leadingIcon: Icons.storefront_outlined,
              onPressed: onBrowse,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Suggested for you" row — a horizontal carousel of designs pulled from a
/// random category. Tapping a card opens the design detail to buy.
class _SuggestedDesigns extends StatelessWidget {
  const _SuggestedDesigns();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

    return BlocBuilder<SuggestedDesignsCubit, SuggestedDesignsState>(
      builder: (context, state) {
        if (state.status == SuggestedDesignsStatus.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: AppLoader()),
          );
        }
        if (state.designs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                strings.suggestedForYou,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelLarge(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Text(
                state.categoryName ?? strings.suggestedForYouSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.designs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) =>
                    _SuggestionCard(item: state.designs[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single suggested-design card (fixed width for the horizontal row).
class _SuggestionCard extends StatelessWidget {
  final DesignItem item;
  const _SuggestionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppLocalization.strings;

    return GestureDetector(
      onTap: () =>
          AppRoutes.push(context, AppRoutes.designDetail, arguments: item.id),
      child: SizedBox(
        width: 150,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                imageUrl: item.firstImageUrl,
                width: double.infinity,
                height: 150,
                memCacheWidth: 300,
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.isFree ? strings.free : '₹${item.finalPrice}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final PurchaseModel purchase;
  const _PurchaseCard({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppLocalization.strings;
    final date = purchase.purchasedAt;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DesignDetailScreen(
            designId: purchase.designId,
            fromPurchases: true,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppNetworkImage(
                imageUrl: purchase.thumbUrl,
                width: double.infinity,
                memCacheWidth: 300,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purchase.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (purchase.fileFormat.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      purchase.fileFormat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '${strings.purchasedOn} $dateLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
