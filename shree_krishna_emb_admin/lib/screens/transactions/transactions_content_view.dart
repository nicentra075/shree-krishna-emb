import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart'
    show OrderModel, OrderStatus;
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart'
    show CatalogStatus, kCatalogPageSizeOptions;
import 'package:shree_krishna_emb_admin/bloc/transactions/orders_cubit.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/transactions/order_detail_dialog.dart';
import 'package:shree_krishna_emb_admin/screens/transactions/widgets/order_status_chip.dart';

/// Admin Transactions list — orders with status filter, date range, search and
/// pagination, plus a per-row detail dialog with a refund action.
class TransactionsContentView extends StatelessWidget {
  const TransactionsContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersCubit>(
      create: (_) => GetIt.instance<OrdersCubit>()..load(),
      child: const _TransactionsBody(),
    );
  }
}

class _TransactionsBody extends StatefulWidget {
  const _TransactionsBody();

  @override
  State<_TransactionsBody> createState() => _TransactionsBodyState();
}

class _TransactionsBodyState extends State<_TransactionsBody> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          final cubit = context.read<OrdersCubit>();
          return Column(
            children: [
              _Toolbar(
                searchController: _searchController,
                state: state,
                onSearch: cubit.setSearch,
                onStatus: cubit.setStatusFilter,
                onPickDateRange: () => _pickDateRange(context, cubit, state),
                onClear: () {
                  _searchController.clear();
                  cubit.setStatusFilter(null);
                  cubit.setDateRange(null, null);
                  cubit.setSearch('');
                },
              ),
              Expanded(child: _body(context, state, cubit, colorScheme)),
              if (state.status == CatalogStatus.loaded &&
                  state.orders.isNotEmpty)
                _PaginationFooter(state: state, cubit: cubit),
            ],
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    OrdersState state,
    OrdersCubit cubit,
    ColorScheme colorScheme,
  ) {
    final strings = AppLocalization.strings;
    if (state.status == CatalogStatus.loading ||
        state.status == CatalogStatus.initial) {
      return const Center(child: AppLoader());
    }
    if (state.status == CatalogStatus.error) {
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
    if (state.orders.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.receipt_long_outlined,
          message: strings.noTransactions,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: state.orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = state.orders[index];
        return _OrderRow(
          order: order,
          dateText: _fmtDate(order.createdAt),
          onTap: () => _openDetail(context, cubit, order),
        );
      },
    );
  }

  Future<void> _pickDateRange(
    BuildContext context,
    OrdersCubit cubit,
    OrdersState state,
  ) async {
    final range = await showDialog<DateTimeRange>(
      context: context,
      builder: (_) => _DateRangeDialog(
        initialStart: state.start,
        initialEnd: state.end,
      ),
    );
    if (range == null) return;
    cubit.setDateRange(
      DateTime(range.start.year, range.start.month, range.start.day),
      DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    OrdersCubit cubit,
    OrderModel order,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider<OrdersCubit>.value(
        value: cubit,
        child: OrderDetailDialog(order: order),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final TextEditingController searchController;
  final OrdersState state;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final VoidCallback onPickDateRange;
  final VoidCallback onClear;

  const _Toolbar({
    required this.searchController,
    required this.state,
    required this.onSearch,
    required this.onStatus,
    required this.onPickDateRange,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final hasFilters =
        (state.search != null && state.search!.isNotEmpty) ||
        state.statusFilter != null ||
        state.start != null;

    final search = AppTextField(
      controller: searchController,
      hint: strings.searchPlaceholder,
      prefixIcon: const Icon(Icons.search, size: 20),
      onChanged: onSearch,
    );
    final dateButton = AppButton(
      label: state.start != null
          ? '${DateFormat('dd MMM').format(state.start!)} - '
                '${DateFormat('dd MMM').format(state.end!)}'
          : strings.selectDateRange,
      leadingIcon: Icons.date_range,
      variant: AppButtonVariant.secondary,
      size: AppButtonSize.medium,
      onPressed: onPickDateRange,
    );
    final clearButton = hasFilters
        ? TextButton.icon(
            onPressed: onClear,
            icon: Icon(Icons.clear, size: 18, color: colorScheme.primary),
            label: Text(
              strings.clearFilters,
              style: AppTextStyles.labelMedium(color: colorScheme.primary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Wide: search grows to fill, controls sit on the right.
          // Narrow: search on its own row, controls wrap below.
          if (constraints.maxWidth >= 720) {
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                _StatusDropdown(value: state.statusFilter, onChanged: onStatus),
                const SizedBox(width: 12),
                dateButton,
                if (clearButton != null) ...[
                  const SizedBox(width: 4),
                  clearButton,
                ],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusDropdown(
                    value: state.statusFilter,
                    onChanged: onStatus,
                  ),
                  dateButton,
                  ?clearButton,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    final entries = <DropdownMenuItem<String?>>[
      DropdownMenuItem(value: null, child: _label(strings.allStatuses)),
      DropdownMenuItem(
        value: OrderStatus.paid.value,
        child: _label(strings.statusPaid),
      ),
      DropdownMenuItem(
        value: OrderStatus.created.value,
        child: _label(strings.statusCreated),
      ),
      DropdownMenuItem(
        value: OrderStatus.failed.value,
        child: _label(strings.statusFailed),
      ),
      DropdownMenuItem(
        value: OrderStatus.refundInitiated.value,
        child: _label(strings.statusRefundInitiated),
      ),
      DropdownMenuItem(
        value: OrderStatus.refunded.value,
        child: _label(strings.statusRefunded),
      ),
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isDense: true,
          dropdownColor: colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
            color: colorScheme.onSurfaceVariant,
          ),
          items: entries,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.labelMedium(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  final String dateText;
  final VoidCallback onTap;

  const _OrderRow({
    required this.order,
    required this.dateText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              // Prefer the buyer's name, then email, then a short user id so the
              // admin can always tell who purchased (older demo orders have no
              // name/email saved).
              final buyer = order.buyerName.isNotEmpty
                  ? order.buyerName
                  : order.buyerEmail.isNotEmpty
                  ? order.buyerEmail
                  : order.userId.isNotEmpty
                  ? order.userId
                  : '—';
              // A ₹0 paid order is a free-design claim — surface it as "Free"
              // instead of "Paid · ₹0".
              final isFree =
                  order.totalAmount == 0 && order.status == OrderStatus.paid;
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id,
                    style: AppTextStyles.labelLarge(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    buyer,
                    style: AppTextStyles.bodySmall(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.items.length} ${strings.items} · $dateText',
                    style: AppTextStyles.labelSmall(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              final amountText = isFree ? strings.free : '₹${order.totalAmount}';
              final statusChip = isFree
                  ? const _FreeChip()
                  : OrderStatusChip(status: order.status);

              final trailing = Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    amountText,
                    style: AppTextStyles.labelLarge(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  statusChip,
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        statusChip,
                        Text(
                          amountText,
                          style: AppTextStyles.labelLarge(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 12),
                  trailing,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A small "Free" pill shown for ₹0 (free-design) orders in place of the Paid
/// status chip.
class _FreeChip extends StatelessWidget {
  const _FreeChip();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF42A5F5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        AppLocalization.strings.free,
        style: AppTextStyles.labelSmall(color: color, fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  final OrdersState state;
  final OrdersCubit cubit;

  const _PaginationFooter({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${strings.perPage}: ',
            style: AppTextStyles.labelSmall(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          DropdownButton<int>(
            value: kCatalogPageSizeOptions.contains(state.pageSize)
                ? state.pageSize
                : kCatalogPageSizeOptions.first,
            underline: const SizedBox(),
            isDense: true,
            dropdownColor: colorScheme.surface,
            style: AppTextStyles.labelMedium(color: colorScheme.onSurface),
            items: kCatalogPageSizeOptions
                .map(
                  (n) => DropdownMenuItem(
                    value: n,
                    child: Text(
                      '$n',
                      style: AppTextStyles.labelMedium(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (size) {
              if (size != null) cubit.setPageSize(size);
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: colorScheme.onSurfaceVariant,
            onPressed: state.page > 1
                ? () => cubit.setPage(state.page - 1)
                : null,
          ),
          Text(
            '${state.page} / ${state.totalPages}',
            style: AppTextStyles.labelMedium(color: colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: colorScheme.onSurfaceVariant,
            onPressed: state.page < state.totalPages
                ? () => cubit.setPage(state.page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

/// A clean From/To date-range picker dialog. Each field opens a compact single
/// date picker; Apply is enabled only once both ends are chosen.
class _DateRangeDialog extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const _DateRangeDialog({this.initialStart, this.initialEnd});

  @override
  State<_DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<_DateRangeDialog> {
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  Future<void> _pick({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? _start ?? now,
      firstDate: isStart ? DateTime(2020) : (_start ?? DateTime(2020)),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        // Keep the range valid: clear an earlier end date.
        if (_end != null && _end!.isBefore(picked)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final canApply = _start != null && _end != null;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(
        strings.selectDateRange,
        style: AppTextStyles.headlineMedium(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 360,
        child: Row(
          children: [
            Expanded(
              child: _dateField(
                label: strings.from,
                value: _start,
                colorScheme: colorScheme,
                onTap: () => _pick(isStart: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dateField(
                label: strings.to,
                value: _end,
                colorScheme: colorScheme,
                onTap: () => _pick(isStart: false),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        AppButton(
          label: strings.ok,
          size: AppButtonSize.small,
          onPressed: canApply
              ? () => Navigator.pop(
                  context,
                  DateTimeRange(start: _start!, end: _end!),
                )
              : null,
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall(color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormat('dd MMM yyyy').format(value)
                        : '—',
                    style: AppTextStyles.bodyMedium(
                      color: value != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
