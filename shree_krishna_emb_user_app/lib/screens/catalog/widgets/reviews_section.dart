import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/models/review_model.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/purchases/purchases_cubit.dart';
import 'package:shree_krishna_emb/bloc/reviews/reviews_cubit.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

/// Reviews block for the design detail screen: average stars, the latest
/// reviews, and a write/edit CTA that is visible only to buyers (rules also
/// enforce this server-side). WS-B2.
class ReviewsSection extends StatefulWidget {
  final String designId;

  const ReviewsSection({required this.designId, super.key});

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  static const _previewCount = 3;
  late final ReviewsCubit _cubit;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ReviewsCubit>(param1: widget.designId);
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openWriteSheet(ReviewModel? existing) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: _cubit,
        child: _WriteReviewSheet(existing: existing),
      ),
    );
    if (submitted == true && mounted) {
      AppSnackbar.showSuccess(AppLocalization.strings.reviewSubmitted);
    }
  }

  Future<void> _confirmDelete() async {
    final strings = AppLocalization.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          strings.deleteReview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          strings.deleteReviewConfirm,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              strings.deleteReview,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _cubit.deleteMyReview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ReviewsCubit, ReviewsState>(
        listener: (context, state) {
          if (state.lastAction == ReviewActionResult.deleted) {
            AppSnackbar.showSuccess(strings.reviewDeleted);
          } else if (state.lastAction == ReviewActionResult.failed) {
            AppSnackbar.showError(state.error ?? strings.somethingWentWrong);
          }
        },
        builder: (context, state) {
          if (state.status == ReviewsStatus.loading ||
              state.status == ReviewsStatus.initial) {
            return const SizedBox.shrink();
          }
          if (state.status == ReviewsStatus.error) {
            return const SizedBox.shrink();
          }

          final visible = _showAll
              ? state.reviews
              : state.reviews.take(_previewCount).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.reviews,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  BlocBuilder<PurchasesCubit, PurchasesState>(
                    builder: (context, purchases) {
                      if (!purchases.isOwned(widget.designId)) {
                        return const SizedBox.shrink();
                      }
                      return TextButton.icon(
                        onPressed: state.submitting
                            ? null
                            : () => _openWriteSheet(state.myReview),
                        icon: Icon(
                          state.myReview == null
                              ? Icons.rate_review_outlined
                              : Icons.edit_outlined,
                          size: 16,
                        ),
                        label: Text(
                          state.myReview == null
                              ? strings.writeReview
                              : strings.editReview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (state.reviews.isEmpty) ...[
                const SizedBox(height: 4),
                BlocBuilder<PurchasesCubit, PurchasesState>(
                  builder: (context, purchases) => Text(
                    purchases.isOwned(widget.designId)
                        ? strings.noReviewsYet
                        : '${strings.noReviewsYet} · ${strings.purchaseToReview}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    AppRatingStars(rating: state.avgRating, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${state.avgRating.toStringAsFixed(1)} · ${strings.reviewsCount(state.reviews.length)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final review in visible)
                  _ReviewTile(
                    review: review,
                    isMine:
                        review.userId == state.myReview?.userId &&
                        state.myReview != null,
                    onDelete: _confirmDelete,
                  ),
                if (state.reviews.length > _previewCount)
                  TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(
                      _showAll ? strings.showLess : strings.viewAll,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  final bool isMine;
  final VoidCallback onDelete;

  const _ReviewTile({
    required this.review,
    required this.isMine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.labelSmall(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppRatingStars(rating: review.rating.toDouble(), size: 12),
                  ],
                ),
              ),
              if (isMine)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: colorScheme.error,
                  ),
                ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment.trim(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WriteReviewSheet extends StatefulWidget {
  final ReviewModel? existing;

  const _WriteReviewSheet({this.existing});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  late int _rating;
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _commentController = TextEditingController(
      text: widget.existing?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<ReviewsCubit>();
    await cubit.submit(
      rating: _rating,
      comment: _commentController.text.trim(),
    );
    if (!mounted) return;
    if (cubit.state.lastAction == ReviewActionResult.failed) {
      AppSnackbar.showError(
        cubit.state.error ?? AppLocalization.strings.somethingWentWrong,
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: BlocBuilder<ReviewsCubit, ReviewsState>(
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.existing == null
                        ? strings.writeReview
                        : strings.editReview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineMedium(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.yourRating,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppRatingStars(
                    rating: _rating.toDouble(),
                    size: 36,
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: strings.reviews,
                    hint: strings.reviewHint,
                    controller: _commentController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: strings.submitReview,
                    onPressed: (_rating >= 1 && !state.submitting)
                        ? _submit
                        : null,
                    isLoading: state.submitting,
                    isFullWidth: true,
                    variant: AppButtonVariant.primary,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
