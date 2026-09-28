import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/models/technician_zone_node.dart';
import '../../models/technician_zone_map_data.dart';
import '../../viewmodels/technician_zone_tree_viewmodel.dart';
import 'technician_breadcrumb_bar.dart';
import 'technician_top_level_zone_card.dart';

enum _DeviceFilter { all, issues, operational }

/// Complete Spatial Explorer view:
/// - At Root: High-fidelity web-parity Big Cards view (matching http://localhost:5173/clientadmin/cameras)
///   with issue-first sorting, health rings, visual device blocks, and status footer.
/// - When Drilled Down: Focused view displaying the selected zone's card.
class ZoneTreeExplorerView extends ConsumerStatefulWidget {
  const ZoneTreeExplorerView({super.key});

  @override
  ConsumerState<ZoneTreeExplorerView> createState() =>
      _ZoneTreeExplorerViewState();
}

class _ZoneTreeExplorerViewState extends ConsumerState<ZoneTreeExplorerView> {
  _DeviceFilter _selectedFilter = _DeviceFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Filters top-level zone Big Cards according to search query and status chip.
  List<TechnicianTopLevelZoneItem> _getFilteredSections(
    List<TechnicianTopLevelZoneItem> sections,
    String query,
    _DeviceFilter filter,
  ) {
    final cleanQuery = query.trim().toLowerCase();

    final result = <TechnicianTopLevelZoneItem>[];
    for (final section in sections) {
      final filteredDevices = section.devices.where((d) {
        if (filter == _DeviceFilter.issues && !section.isDeviceDefective(d)) {
          return false;
        }
        if (filter == _DeviceFilter.operational &&
            section.isDeviceDefective(d)) {
          return false;
        }
        if (cleanQuery.isNotEmpty) {
          final matchesName = d.name.toLowerCase().contains(cleanQuery);
          final matchesCode = d.code.toLowerCase().contains(cleanQuery);
          final matchesLoc = d.location.toLowerCase().contains(cleanQuery);
          final matchesZone =
              section.zone.name.toLowerCase().contains(cleanQuery);
          if (!matchesName && !matchesCode && !matchesLoc && !matchesZone) {
            return false;
          }
        }
        return true;
      }).toList();

      final zoneNameMatches = cleanQuery.isNotEmpty &&
          section.zone.name.toLowerCase().contains(cleanQuery);
      if (filteredDevices.isNotEmpty ||
          (zoneNameMatches && filter == _DeviceFilter.all)) {
        result.add(section.copyWith(
          devices: filteredDevices,
        ));
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final treeAsync = ref.watch(technicianZoneTreeViewModelProvider);
    final viewModel = ref.read(technicianZoneTreeViewModelProvider.notifier);

    return treeAsync.when(
      loading: () => const ZoneTreeSkeleton(),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                l10n.techFailedToLoadZones('$err'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => viewModel.refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (state) {
        final isAtRoot = state.isAtRoot;

        // ════════════════════════════════════════════════════════════════════
        // 1. ROOT VIEW: High-Fidelity Web-Parity Big Cards View
        // ════════════════════════════════════════════════════════════════════
        if (isAtRoot) {
          final filteredSections = _getFilteredSections(
            state.zoneSections,
            _searchQuery,
            _selectedFilter,
          );

          var totalDevices = 0;
          var totalOnline = 0;
          var totalOffline = 0;
          for (final sec in state.zoneSections) {
            totalDevices += sec.totalDevices;
            totalOnline += sec.onlineDevices;
            totalOffline += sec.offlineDevices;
          }
          final fleetHealthPct = totalDevices > 0
              ? ((totalOnline / totalDevices) * 100).toStringAsFixed(0)
              : '100';

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => viewModel.refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Top Search & Filter Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _searchFocusNode.hasFocus
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: _searchFocusNode.hasFocus ? 1.5 : 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: _searchFocusNode.hasFocus
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: (val) =>
                                      setState(() => _searchQuery = val),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search equipment by code, name, or subzone...',
                                    hintStyle: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 11),
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: Icon(Icons.close_rounded,
                                      size: 16, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Filter Chips & Fleet Health Indicator
                        Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    AppFilterChip(
                                      label: 'All',
                                      badgeText: '$totalDevices',
                                      isSelected:
                                          _selectedFilter == _DeviceFilter.all,
                                      onTap: () => setState(() =>
                                          _selectedFilter = _DeviceFilter.all),
                                    ),
                                    const SizedBox(width: 8),
                                    AppFilterChip(
                                      label: 'Active',
                                      badgeText: '$totalOnline',
                                      badgeColor: totalOnline > 0
                                          ? AppColors.success
                                          : null,
                                      isSelected: _selectedFilter ==
                                          _DeviceFilter.operational,
                                      activeColor: AppColors.success,
                                      onTap: () => setState(() =>
                                          _selectedFilter =
                                              _DeviceFilter.operational),
                                    ),
                                    const SizedBox(width: 8),
                                    AppFilterChip(
                                      label: 'Issues',
                                      badgeText: '$totalOffline',
                                      badgeColor: totalOffline > 0
                                          ? AppColors.error
                                          : null,
                                      isSelected: _selectedFilter ==
                                          _DeviceFilter.issues,
                                      activeColor: AppColors.error,
                                      onTap: () => setState(() =>
                                          _selectedFilter =
                                              _DeviceFilter.issues),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: totalOffline > 0
                                    ? AppColors.error.withValues(alpha: 0.1)
                                    : AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: totalOffline > 0
                                      ? AppColors.error.withValues(alpha: 0.3)
                                      : AppColors.success.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: totalOffline > 0
                                          ? AppColors.error
                                          : AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$fleetHealthPct% Health',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: totalOffline > 0
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Error banner if any
                if (state.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Big Cards List (Issue-First Sorted)
                if (filteredSections.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return TechnicianTopLevelZoneCard(
                            zoneItem: filteredSections[index],
                          );
                        },
                        childCount: filteredSections.length,
                      ),
                    ),
                  )
                else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 40),
                      child: EmptyStateView(
                        icon: state.zoneSections.isEmpty
                            ? Icons.map_outlined
                            : Icons.search_off_rounded,
                        title: state.zoneSections.isEmpty
                            ? l10n.techNoAssignedZones
                            : 'No Matching Equipment',
                        subtitle: state.zoneSections.isEmpty
                            ? l10n.techNoAssignedZonesSub
                            : 'No zones or equipment match your current search and filter criteria.',
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        // ════════════════════════════════════════════════════════════════════
        // 2. DRILLED DOWN VIEW: Focused Breadcrumb Navigation
        // ════════════════════════════════════════════════════════════════════
        final currentZone = state.currentZone;
        final focusedSection = state.zoneSections
            .where((s) => s.zone.id == currentZone?.id)
            .firstOrNull ??
            TechnicianTopLevelZoneItem(
              zone: currentZone ?? const TechnicianZoneNode(id: '', name: ''),
              devices: state.currentDevices,
              issues: state.currentIssues,
            );

        return Column(
          children: [
            // Breadcrumbs Bar
            TechnicianBreadcrumbBar(
              currentPath: state.currentPath,
              onNavigateUp: () => viewModel.navigateUp(),
              onJumpToRoot: () => viewModel.jumpToRoot(),
              onJumpToBreadcrumb: (index) => viewModel.jumpToBreadcrumb(index),
            ),

            if (state.isDrillingDown)
              LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: AppColors.transparent,
                color: AppColors.primary,
              ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => viewModel.refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    TechnicianTopLevelZoneCard(
                      zoneItem: focusedSection,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
