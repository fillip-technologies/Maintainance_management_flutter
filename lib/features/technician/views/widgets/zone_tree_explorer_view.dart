import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/models/device_model.dart';
import '../../../issues/issues.dart';
import '../../models/technician_zone_map_data.dart';
import '../../viewmodels/technician_action_viewmodel.dart';
import '../../viewmodels/technician_zone_tree_viewmodel.dart';
import 'subzone_grid_card.dart';
import 'technician_breadcrumb_bar.dart';
import 'technician_device_detail_sheet.dart';
import 'technician_issue_card.dart';
import 'technician_top_level_zone_card.dart';
import 'zone_device_card.dart';
import 'zone_health_hero_card.dart';

enum _DeviceFilter { all, issues, operational }

/// Complete Spatial Explorer view:
/// - At Root: High-fidelity web-parity Big Cards view (matching http://localhost:5173/clientadmin/products)
///   with issue-first sorting, health rings, visual device blocks, and 2-column subzone cards.
/// - When Drilled Down: Breadcrumb-guided hierarchy explorer for focused inspection.
class ZoneTreeExplorerView extends ConsumerStatefulWidget {
  const ZoneTreeExplorerView({super.key});

  @override
  ConsumerState<ZoneTreeExplorerView> createState() =>
      _ZoneTreeExplorerViewState();
}

class _ZoneTreeExplorerViewState extends ConsumerState<ZoneTreeExplorerView> {
  _DeviceFilter _selectedFilter = _DeviceFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
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
      // 1. Filter direct devices
      final filteredDirect = section.directDevices.where((d) {
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

      // 2. Filter nested subzones
      final filteredSubzones = <TechnicianSubzoneItem>[];
      for (final sz in section.subzones) {
        final filteredSzDevices = sz.devices.where((d) {
          if (filter == _DeviceFilter.issues && !sz.isDeviceDefective(d)) {
            return false;
          }
          if (filter == _DeviceFilter.operational && sz.isDeviceDefective(d)) {
            return false;
          }
          if (cleanQuery.isNotEmpty) {
            final matchesName = d.name.toLowerCase().contains(cleanQuery);
            final matchesCode = d.code.toLowerCase().contains(cleanQuery);
            final matchesLoc = d.location.toLowerCase().contains(cleanQuery);
            final matchesSz = sz.zone.name.toLowerCase().contains(cleanQuery);
            final matchesZone =
                section.zone.name.toLowerCase().contains(cleanQuery);
            if (!matchesName &&
                !matchesCode &&
                !matchesLoc &&
                !matchesSz &&
                !matchesZone) {
              return false;
            }
          }
          return true;
        }).toList();

        final szNameMatches = cleanQuery.isNotEmpty &&
            sz.zone.name.toLowerCase().contains(cleanQuery);
        if (filteredSzDevices.isNotEmpty ||
            (szNameMatches && filter == _DeviceFilter.all)) {
          filteredSubzones.add(sz.copyWith(devices: filteredSzDevices));
        }
      }

      final zoneNameMatches = cleanQuery.isNotEmpty &&
          section.zone.name.toLowerCase().contains(cleanQuery);
      if (filteredDirect.isNotEmpty ||
          filteredSubzones.isNotEmpty ||
          (zoneNameMatches && filter == _DeviceFilter.all)) {
        result.add(section.copyWith(
          directDevices: filteredDirect,
          subzones: filteredSubzones,
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
    final actionNotifier = ref.read(technicianActionViewModelProvider);

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
                            border: Border.all(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded,
                                  size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
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
        final displayedSubzones = state.currentSubzones;
        final devices = state.currentDevices;
        final issues = state.currentIssues
            .where((i) =>
                i.status != IssueStatus.resolved &&
                i.status != IssueStatus.closed)
            .toList();

        final deviceIdsInZone = {for (final d in devices) d.id};

        bool isDeviceDefective(DeviceModel d) {
          return issues.any((iss) => iss.deviceId == d.id) ||
              d.status == DeviceStatus.faulty ||
              d.status == DeviceStatus.underMaintenance;
        }

        final defectiveDevices = devices.where(isDeviceDefective).toList();
        final operationalDevices =
            devices.where((d) => !isDeviceDefective(d)).toList();

        final List<DeviceModel> displayedDevices;
        switch (_selectedFilter) {
          case _DeviceFilter.issues:
            displayedDevices = defectiveDevices;
            break;
          case _DeviceFilter.operational:
            displayedDevices = operationalDevices;
            break;
          case _DeviceFilter.all:
            displayedDevices = [...defectiveDevices, ...operationalDevices];
            break;
        }

        final facilityIncidents = issues
            .where((iss) =>
                iss.deviceId.isEmpty || !deviceIdsInZone.contains(iss.deviceId))
            .toList();

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
                  padding: const EdgeInsets.only(bottom: 32),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    // 1. Health Hero Card
                    ZoneHealthHeroCard(
                      focusedZone: currentZone,
                      rootZones: state.rootZones,
                    ),

                    // Optional Error Banner
                    if (state.errorMessage != null) ...[
                      Container(
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
                    ],

                    // 2. Sub-zones Grid
                    if (displayedSubzones.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_tree_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.techSubZonesCount(displayedSubzones.length),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _TwoColumnGrid(
                          children: [
                            for (var i = 0; i < displayedSubzones.length; i++)
                              SubzoneGridCard(
                                zone: displayedSubzones[i],
                                index: i,
                                onTap: () =>
                                    viewModel.drillDown(displayedSubzones[i]),
                              ),
                          ],
                        ),
                      ),
                    ],

                    // Empty state if leaf zone with 0 devices and 0 incidents
                    if (displayedSubzones.isEmpty &&
                        devices.isEmpty &&
                        facilityIncidents.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: EmptyStateView(
                          icon: Icons.devices_other_outlined,
                          title: 'No Hardware Registered',
                          subtitle:
                              'There is currently no equipment assigned to this zone.',
                        ),
                      ),
                    ],

                    // 3. Hardware Units: Visual 2-Column Card Grid
                    if (devices.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.devices_other_rounded,
                                  size: 15,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'HARDWARE IN ZONE (${devices.length})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const Spacer(),
                                if (defectiveDevices.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.error
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.error
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.warning_amber_rounded,
                                            size: 11, color: AppColors.error),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${defectiveDevices.length}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppColors.success
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          size: 11,
                                          color: AppColors.successText),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${operationalDevices.length}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.successText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  AppFilterChip(
                                    label: 'All',
                                    badgeText: '${devices.length}',
                                    isSelected:
                                        _selectedFilter == _DeviceFilter.all,
                                    onTap: () => setState(() =>
                                        _selectedFilter = _DeviceFilter.all),
                                  ),
                                  const SizedBox(width: 8),
                                  AppFilterChip(
                                    label: 'Issues',
                                    badgeText: '${defectiveDevices.length}',
                                    badgeColor: defectiveDevices.isNotEmpty
                                        ? AppColors.error
                                        : null,
                                    isSelected:
                                        _selectedFilter == _DeviceFilter.issues,
                                    activeColor: AppColors.error,
                                    onTap: () => setState(() =>
                                        _selectedFilter = _DeviceFilter.issues),
                                  ),
                                  const SizedBox(width: 8),
                                  AppFilterChip(
                                    label: 'Working',
                                    badgeText: '${operationalDevices.length}',
                                    badgeColor: operationalDevices.isNotEmpty
                                        ? AppColors.success
                                        : null,
                                    isSelected: _selectedFilter ==
                                        _DeviceFilter.operational,
                                    activeColor: AppColors.success,
                                    onTap: () => setState(() => _selectedFilter =
                                        _DeviceFilter.operational),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (displayedDevices.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Center(
                              child: Text(
                                _selectedFilter == _DeviceFilter.issues
                                    ? 'No equipment with open issues in this zone.'
                                    : 'No equipment matches this filter.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _TwoColumnGrid(
                            children: [
                              for (final dev in displayedDevices)
                                ZoneDeviceCard(
                                  device: dev,
                                  activeIssues: issues
                                      .where((iss) => iss.deviceId == dev.id)
                                      .toList(),
                                  onInspectIssue: (issue) =>
                                      IssueDetailSheet.show(context, issue),
                                  onInspectDevice: (device) =>
                                      TechnicianDeviceDetailSheet.show(
                                    context,
                                    device: device,
                                    onReportIssue: () {
                                      RaiseIssueSheet.show(
                                        context,
                                        devices: devices,
                                        initialDevice: device,
                                        onIssueCreated: (_) =>
                                            viewModel.refresh(),
                                      );
                                    },
                                  ),
                                  onUpdateIssueStatus: (issue, newStatus) {
                                    final issueId = issue.id;
                                    UpdateStatusSheet.show(
                                      context,
                                      issue: issue,
                                      initialTargetStatus: newStatus,
                                      onStatusUpdated: (status, comment, photo,
                                          [latitude, longitude]) async {
                                        try {
                                          await actionNotifier.updateStatus(
                                            issueId: issueId,
                                            toStatus: status,
                                            notes: comment,
                                            attachments:
                                                photo != null ? [photo] : null,
                                            latitude: latitude,
                                            longitude: longitude,
                                          );
                                          viewModel.refresh();
                                        } catch (e) {
                                          AppSnackbar.error(
                                              'Failed to update status: $e');
                                          rethrow;
                                        }
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                    ],

                    // 4. Area-Level Incidents
                    if (facilityIncidents.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.techFacilityIncidentsCount(
                                  facilityIncidents.length),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warningText,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            for (final issue in facilityIncidents)
                              TechnicianIssueCard(
                                issue: issue,
                                onTap: () =>
                                    IssueDetailSheet.show(context, issue),
                                onUpdateStatus: (newStatus) {
                                  final issueId = issue.id;
                                  UpdateStatusSheet.show(
                                    context,
                                    issue: issue,
                                    initialTargetStatus: newStatus,
                                    onStatusUpdated: (status, comment, photo,
                                        [latitude, longitude]) async {
                                      try {
                                        await actionNotifier.updateStatus(
                                          issueId: issueId,
                                          toStatus: status,
                                          notes: comment,
                                          attachments:
                                              photo != null ? [photo] : null,
                                          latitude: latitude,
                                          longitude: longitude,
                                        );
                                        viewModel.refresh();
                                      } catch (e) {
                                        AppSnackbar.error(
                                            'Failed to update status: $e');
                                        rethrow;
                                      }
                                    },
                                  );
                                },
                                onOpenTimeline: () =>
                                    IssueDetailSheet.show(context, issue),
                              ),
                          ],
                        ),
                      ),
                    ],

                    // 5. Empty state if leaf zone with 0 subzones and 0 unresolved items
                    if (displayedSubzones.isEmpty &&
                        displayedDevices.isEmpty &&
                        facilityIncidents.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EmptyStateView(
                          icon: Icons.check_circle_outline_rounded,
                          title: l10n.techAllUnitsOperational,
                          subtitle: devices.isNotEmpty
                              ? l10n.techAllUnitsOperationalSub(
                                  devices.length,
                                  currentZone?.name ?? l10n.techAllZones,
                                )
                              : l10n.techNoUnresolvedInZone(
                                  currentZone?.name ?? l10n.techAllZones,
                                ),
                        ),
                      ),
                    ],
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

/// Two-column card grid whose rows size to their tallest card instead of a fixed aspect ratio.
class _TwoColumnGrid extends StatelessWidget {
  final List<Widget> children;
  const _TwoColumnGrid({required this.children});

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final right = i + 1 < children.length ? children[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: _gap),
              Expanded(
                child: right ?? const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < children.length) rows.add(const SizedBox(height: _gap));
    }
    return Column(children: rows);
  }
}
