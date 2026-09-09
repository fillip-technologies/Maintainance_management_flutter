import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/technician_zone_tree_state.dart';
import '../../models/zone_status_row.dart';
import '../../viewmodels/technician_view_mode_provider.dart';
import '../../viewmodels/technician_zone_status_viewmodel.dart';
import '../../viewmodels/technician_zone_tree_viewmodel.dart';

const double _indexColWidth = 22.0;
const double _totalColWidth = 44.0;
const double _onlineColWidth = 42.0;
const double _offlineColWidth = 42.0;
const double _maintColWidth = 40.0;
const double _statusColWidth = 60.0;
const double _rowHorizontalPadding = 6.0;
const double _fixedColumnsWidth = _indexColWidth +
    _totalColWidth +
    _onlineColWidth +
    _offlineColWidth +
    _maintColWidth +
    _statusColWidth; // 250.0

/// Calculates the exact width needed for the Zone / Area column based on the longest
/// zone name in the list, allowing the table to remain as compact as possible on mobile.
double _calculateMaxZoneWidth({
  required BuildContext context,
  required List<ZoneStatusRow> rows,
  required String headerText,
}) {
  final textScaler = MediaQuery.textScalerOf(context);

  // Measure header text width
  final headerPainter = TextPainter(
    text: TextSpan(
      text: headerText,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();
  double maxContentWidth = headerPainter.width;

  // Measure each row's zone name + icon (20px) + gap (6px)
  for (final row in rows) {
    final painter = TextPainter(
      text: TextSpan(
        text: row.displayName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();

    final rowWidth = 26.0 + painter.width;
    if (rowWidth > maxContentWidth) {
      maxContentWidth = rowWidth;
    }
  }

  // 6px extra padding buffer for comfortable spacing
  return maxContentWidth + 6.0;
}

/// Tabular overview of every assigned zone/area and its hardware health metrics.
///
/// Designed to be faithful to the compact dashboard mockup:
/// | # | Zone / Area | Hardware | Online | Offline | Maint. | Status |
class TechnicianZoneStatusView extends ConsumerWidget {
  const TechnicianZoneStatusView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statusAsync = ref.watch(technicianZoneStatusViewModelProvider);

    return statusAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => ErrorStateView(
        title: l10n.zoneStatusLoadFailed,
        subtitle: error.toString(),
        retryLabel: l10n.retry,
        onRetry: () =>
            ref.read(technicianZoneStatusViewModelProvider.notifier).refresh(),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return EmptyStateView(
            icon: Icons.grid_view_rounded,
            title: l10n.zoneStatusEmpty,
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bar: Title, Count, Refresh action
              Row(
                children: [
                  Text(
                    l10n.zoneStatusTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${rows.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    color: AppColors.textSecondary,
                    tooltip: l10n.retry,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref
                        .read(technicianZoneStatusViewModelProvider.notifier)
                        .refresh(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Table card container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double calculatedZoneWidth = _calculateMaxZoneWidth(
                        context: context,
                        rows: rows,
                        headerText: l10n.zoneStatusColZone,
                      );

                      final double minNeededWidth = _fixedColumnsWidth +
                          (_rowHorizontalPadding * 2) +
                          calculatedZoneWidth;

                      final double tableWidth = constraints.maxWidth > minNeededWidth
                          ? constraints.maxWidth
                          : minNeededWidth;

                      final double zoneColWidth = constraints.maxWidth > minNeededWidth
                          ? calculatedZoneWidth + (constraints.maxWidth - minNeededWidth)
                          : calculatedZoneWidth;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: Column(
                            children: [
                              // Sticky Table Header
                              _TableHeader(
                                zoneColWidth: zoneColWidth,
                                l10n: l10n,
                              ),
                              const Divider(height: 1, thickness: 1, color: AppColors.border),

                              // Table Rows with Pull-to-refresh
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () => ref
                                      .read(technicianZoneStatusViewModelProvider.notifier)
                                      .refresh(),
                                  child: ListView.separated(
                                    itemCount: rows.length,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    separatorBuilder: (_, _) => Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: AppColors.divider.withValues(alpha: 0.6),
                                    ),
                                    itemBuilder: (context, index) {
                                      final row = rows[index];
                                      return _ZoneRow(
                                        row: row,
                                        index: index,
                                        zoneColWidth: zoneColWidth,
                                        l10n: l10n,
                                        onTap: () {
                                          ref
                                              .read(technicianViewModeProvider.notifier)
                                              .setMode(TechnicianViewMode.spatialExplorer);
                                          ref
                                              .read(technicianZoneTreeViewModelProvider.notifier)
                                              .navigateToZone(
                                                row.id,
                                                zoneName: row.name,
                                                imageUrl: row.imageUrl,
                                                fromZoneStatus: true,
                                              );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Sticky table header with fixed column proportions.
class _TableHeader extends StatelessWidget {
  final double zoneColWidth;
  final AppLocalizations l10n;

  const _TableHeader({
    required this.zoneColWidth,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: _rowHorizontalPadding),
      color: AppColors.cardAlt,
      child: Row(
        children: [
          const SizedBox(
            width: _indexColWidth,
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: zoneColWidth,
            child: Text(
              l10n.zoneStatusColZone,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: _totalColWidth,
            child: Text(
              l10n.zoneStatusColHardware,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: _onlineColWidth,
            child: Text(
              l10n.zoneStatusColOnline,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: _offlineColWidth,
            child: Text(
              l10n.zoneStatusColOffline,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: _maintColWidth,
            child: Text(
              l10n.zoneStatusColMaint,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: _statusColWidth,
            child: Text(
              l10n.zoneStatusColStatus,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single data row representing a zone's hardware counts and overall health.
class _ZoneRow extends StatelessWidget {
  final ZoneStatusRow row;
  final int index;
  final double zoneColWidth;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  const _ZoneRow({
    required this.row,
    required this.index,
    required this.zoneColWidth,
    required this.l10n,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAlerted = row.isAlerted;

    return Material(
      color: isAlerted
          ? AppColors.errorLight.withValues(alpha: 0.65)
          : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: _rowHorizontalPadding),
          child: Row(
            children: [
              // # Index
              SizedBox(
                width: _indexColWidth,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isAlerted ? AppColors.errorText : AppColors.textSecondary,
                  ),
                ),
              ),

              // Zone / Area Cell (sized to max name width)
              SizedBox(
                width: zoneColWidth,
                child: _ZoneCell(
                  name: row.displayName,
                  imageUrl: row.imageUrl,
                ),
              ),

              // Total Count (Total column, centered)
              SizedBox(
                width: _totalColWidth,
                child: Text(
                  row.dataLoadFailed ? '—' : '${row.hardwareCount}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // Online Count
              SizedBox(
                width: _onlineColWidth,
                child: _CountCell(
                  value: row.onlineCount,
                  dotColor: AppColors.success,
                  dataLoadFailed: row.dataLoadFailed,
                ),
              ),

              // Offline Count
              SizedBox(
                width: _offlineColWidth,
                child: _CountCell(
                  value: row.offlineCount,
                  dotColor: AppColors.error,
                  dataLoadFailed: row.dataLoadFailed,
                ),
              ),

              // Maint. Count
              SizedBox(
                width: _maintColWidth,
                child: _CountCell(
                  value: row.maintenanceCount,
                  dotColor: AppColors.warning,
                  dataLoadFailed: row.dataLoadFailed,
                ),
              ),

              // Overall Status (colored circle + text, no background pill)
              SizedBox(
                width: _statusColWidth,
                child: _StatusIndicator(
                  status: row.overallStatus,
                  dataLoadFailed: row.dataLoadFailed,
                  l10n: l10n,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zone name and leading visual icon / thumbnail.
class _ZoneCell extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _ZoneCell({
    required this.name,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.cardAlt,
            borderRadius: BorderRadius.circular(5),
          ),
          child: (imageUrl != null && imageUrl!.isNotEmpty)
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Compact count cell with 6x6 status dot and numeric value.
class _CountCell extends StatelessWidget {
  final int value;
  final Color dotColor;
  final bool dataLoadFailed;

  const _CountCell({
    required this.value,
    required this.dotColor,
    this.dataLoadFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dataLoadFailed) {
      return const Text(
        '—',
        style: TextStyle(
          fontSize: 11.5,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final isZero = value == 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isZero ? AppColors.iconLight.withValues(alpha: 0.5) : dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isZero ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Circular status indicator with colored circle and default text color (no background pill).
class _StatusIndicator extends StatelessWidget {
  final ZoneOverallStatus status;
  final bool dataLoadFailed;
  final AppLocalizations l10n;

  const _StatusIndicator({
    required this.status,
    this.dataLoadFailed = false,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (dataLoadFailed) {
      return const Text(
        '—',
        style: TextStyle(
          fontSize: 11.5,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final isOnline = status == ZoneOverallStatus.online;
    final dotColor = isOnline ? AppColors.success : AppColors.error;
    final label = isOnline ? l10n.zoneStatusOnline : l10n.zoneStatusOffline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
