import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/reports/reports_cubit.dart';
import 'package:shree_krishna_emb_admin/core/utils/csv_exporter.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_reports_datasource.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

/// Admin Reports: KPI cards + top designs/categories + date-range filter and
/// CSV export (sales summary + line items), all honoring the date filter.
class ReportsContentView extends StatelessWidget {
  const ReportsContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReportsCubit>(
      create: (_) => GetIt.instance<ReportsCubit>()..load(),
      child: const _ReportsBody(),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          final cubit = context.read<ReportsCubit>();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _toolbar(context, state, cubit, strings, colorScheme),
                const SizedBox(height: 20),
                if (state.status == ReportsStatus.loading ||
                    state.status == ReportsStatus.initial)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: AppLoader()),
                  )
                else if (state.status == ReportsStatus.error)
                  _errorBox(context, state, cubit, strings, colorScheme)
                else
                  _content(context, state.report, strings, colorScheme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _toolbar(
    BuildContext context,
    ReportsState state,
    ReportsCubit cubit,
    dynamic strings,
    ColorScheme colorScheme,
  ) {
    final df = DateFormat('dd MMM yyyy');
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          strings.reports,
          style: AppTextStyles.headlineMedium(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 8),
        AppButton(
          label: '${df.format(state.start)} - ${df.format(state.end)}',
          leadingIcon: Icons.date_range,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.medium,
          onPressed: () => _pickRange(context, state, cubit),
        ),
        AppButton(
          label: strings.exportSalesSummary,
          leadingIcon: Icons.download,
          size: AppButtonSize.medium,
          onPressed: state.report == null
              ? () {}
              : () => _exportSummary(context, state, strings),
        ),
        AppButton(
          label: strings.exportLineItems,
          leadingIcon: Icons.download,
          variant: AppButtonVariant.outlined,
          size: AppButtonSize.medium,
          onPressed: (state.report?.lineItems.isEmpty ?? true)
              ? () {}
              : () => _exportLineItems(context, state, strings),
        ),
      ],
    );
  }

  Widget _errorBox(
    BuildContext context,
    ReportsState state,
    ReportsCubit cubit,
    dynamic strings,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
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
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ReportSummary? report,
    dynamic strings,
    ColorScheme colorScheme,
  ) {
    if (report == null || report.paidOrders == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: AppEmptyState(
            icon: Icons.bar_chart_outlined,
            message: strings.noReportData,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            final cardWidth = isMobile
                ? constraints.maxWidth
                : (constraints.maxWidth - 48) / 4;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _kpiCard(
                  context,
                  cardWidth,
                  Icons.payments_outlined,
                  strings.totalSales,
                  '₹${report.totalSales}',
                ),
                _kpiCard(
                  context,
                  cardWidth,
                  Icons.receipt_long_outlined,
                  strings.ordersCount,
                  '${report.paidOrders}',
                ),
                _kpiCard(
                  context,
                  cardWidth,
                  Icons.trending_up,
                  strings.averageOrderValue,
                  '₹${report.averageOrderValue}',
                ),
                _kpiCard(
                  context,
                  cardWidth,
                  Icons.person_add_outlined,
                  strings.newUsers,
                  '${report.newUsers}',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            final design = _rankedTable(
              context,
              strings.topDesigns,
              report.topDesigns,
              strings,
            );
            final category = _rankedTable(
              context,
              strings.topCategories,
              report.topCategories,
              strings,
            );
            if (isMobile) {
              return Column(
                children: [design, const SizedBox(height: 16), category],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: design),
                const SizedBox(width: 16),
                Expanded(child: category),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _kpiCard(
    BuildContext context,
    double width,
    IconData icon,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 14),
          Text(
            value,
            style: AppTextStyles.headlineMedium(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _rankedTable(
    BuildContext context,
    String title,
    List<RankedRow> rows,
    dynamic strings,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelLarge(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                strings.noReportData,
                style: AppTextStyles.bodySmall(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.label,
                        style: AppTextStyles.bodyMedium(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${r.unitsSold} ${strings.unitsSold}',
                      style: AppTextStyles.labelSmall(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '₹${r.revenue}',
                      style: AppTextStyles.labelMedium(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickRange(
    BuildContext context,
    ReportsState state,
    ReportsCubit cubit,
  ) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: state.start, end: state.end),
    );
    if (range == null) return;
    cubit.setDateRange(range.start, range.end);
  }

  String _fileSuffix(ReportsState state) {
    final df = DateFormat('yyyyMMdd');
    return '${df.format(state.start)}_${df.format(state.end)}';
  }

  Future<void> _exportSummary(
    BuildContext context,
    ReportsState state,
    dynamic strings,
  ) async {
    final r = state.report;
    if (r == null) return;
    final csv = CsvExporter.build(
      ['Metric', 'Value'],
      [
        ['Total Sales (INR)', r.totalSales],
        ['Paid Orders', r.paidOrders],
        ['Average Order Value (INR)', r.averageOrderValue],
        ['Platform Fees (INR)', r.totalPlatformFees],
        ['GST (INR)', r.totalGst],
        ['New Users', r.newUsers],
        ['Range Start', DateFormat('yyyy-MM-dd').format(state.start)],
        ['Range End', DateFormat('yyyy-MM-dd').format(state.end)],
      ],
    );
    await _deliver(
      context,
      csv,
      'sales_summary_${_fileSuffix(state)}.csv',
      strings,
    );
  }

  Future<void> _exportLineItems(
    BuildContext context,
    ReportsState state,
    dynamic strings,
  ) async {
    final r = state.report;
    if (r == null) return;
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final csv = CsvExporter.build(
      [
        'Order ID',
        'Date',
        'Buyer',
        'Email',
        'Status',
        'Design ID',
        'Design',
        'Category',
        'Price (INR)',
        'Invoice',
      ],
      r.lineItems
          .map(
            (li) => [
              li.orderId,
              df.format(li.date),
              li.buyerName,
              li.buyerEmail,
              li.status,
              li.designId,
              li.designTitle,
              li.categoryName,
              li.price,
              li.invoiceNumber,
            ],
          )
          .toList(),
    );
    await _deliver(
      context,
      csv,
      'line_items_${_fileSuffix(state)}.csv',
      strings,
    );
  }

  Future<void> _deliver(
    BuildContext context,
    String csv,
    String filename,
    dynamic strings,
  ) async {
    final ok = CsvExporter.download(csv, filename);
    if (!context.mounted) return;
    if (ok) {
      ResponsiveSnackbar.showSuccess(strings.exportSuccess, context);
    } else {
      // Fallback: copy to clipboard (non-web or download blocked).
      await CsvExporter.copyToClipboard(csv);
      if (!context.mounted) return;
      ResponsiveSnackbar.showInfo(strings.exportCopiedToClipboard, context);
    }
  }
}
