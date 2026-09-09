import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/zone_status_row.dart';
import '../../viewmodels/technician_zone_status_viewmodel.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      const double minTableWidth = 450.0;
                      final double tableWidth = constraints.maxWidth > minTableWidth
                          ? constraints.maxWidth
                          : minTableWidth;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: Column(
                            children: [
                              // Sticky Table Header
                              _TableHeader(l10n: l10n),
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
                                      return _ZoneRow(
                                        row: rows[index],
                                        index: index,
                                        l10n: l10n,
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
  final AppLocalizations l10n;

  const _TableHeader({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.cardAlt,
      child: Row(
        children: [
          const SizedBox(
            width: 26,
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
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
            width: 52,
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
            width: 48,
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
            width: 48,
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
            width: 46,
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
            width: 68,
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
  final AppLocalizations l10n;

  const _ZoneRow({
    required this.row,
    required this.index,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          // # Index
          SizedBox(
            width: 26,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Zone / Area Cell
          Expanded(
            child: _ZoneCell(
              name: row.displayName,
              imageUrl: row.imageUrl,
            ),
          ),

          // Hardware Count (Cameras column in mock)
          SizedBox(
            width: 52,
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
            width: 48,
            child: _CountCell(
              value: row.onlineCount,
              dotColor: AppColors.success,
              dataLoadFailed: row.dataLoadFailed,
            ),
          ),

          // Offline Count
          SizedBox(
            width: 48,
            child: _CountCell(
              value: row.offlineCount,
              dotColor: AppColors.error,
              dataLoadFailed: row.dataLoadFailed,
            ),
          ),

          // Maint. Count
          SizedBox(
            width: 46,
            child: _CountCell(
              value: row.maintenanceCount,
              dotColor: AppColors.warning,
              dataLoadFailed: row.dataLoadFailed,
            ),
          ),

          // Overall Status (colored circle + text, no background pill)
          SizedBox(
            width: 68,
            child: _StatusIndicator(
              status: row.overallStatus,
              dataLoadFailed: row.dataLoadFailed,
              l10n: l10n,
            ),
          ),
        ],
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
