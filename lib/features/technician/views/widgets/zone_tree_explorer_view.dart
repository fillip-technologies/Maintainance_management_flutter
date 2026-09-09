import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../issues/issues.dart';
import '../../viewmodels/technician_action_viewmodel.dart';
import '../../viewmodels/technician_zone_tree_viewmodel.dart';
import 'subzone_grid_card.dart';
import 'technician_breadcrumb_bar.dart';
import 'technician_issue_card.dart';
import 'zone_device_card.dart';
import 'zone_health_hero_card.dart';

/// Complete Spatial Explorer view providing zone-tree breadcrumb navigation,
/// visual health cards, and tactile 2-column CARD grids (not lists) with prominent
/// RED backgrounds for defective units and GREEN for healthy ones.
class ZoneTreeExplorerView extends ConsumerStatefulWidget {
  const ZoneTreeExplorerView({super.key});

  @override
  ConsumerState<ZoneTreeExplorerView> createState() => _ZoneTreeExplorerViewState();
}

class _ZoneTreeExplorerViewState extends ConsumerState<ZoneTreeExplorerView> {
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
              Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
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
        final currentZone = state.currentZone;
        final displayedSubzones = isAtRoot ? state.rootZones : state.currentSubzones;
        final devices = state.currentDevices;
        // Spatial Explorer: Active issues only (never show resolved in spatial explore)
        final issues = state.currentIssues
            .where((i) =>
                i.status != IssueStatus.resolved &&
                i.status != IssueStatus.closed)
            .toList();

        // Spatial Explorer: ONLY show devices that have UNRESOLVED issues!
        final deviceIdsInZone = {for (final d in devices) d.id};
        final displayedDevices = devices
            .where((d) => issues.any((iss) => iss.deviceId == d.id))
            .toList();

        // Facility incidents: every active issue in this subtree that isn't
        // pinned to one of the devices shown above — device-less area incidents
        // AND issues on devices that live in a deeper sub-zone. Previously these
        // were filtered to `iss.zoneId == currentZone.id` and silently vanished
        // at every level when they belonged to a nested zone. The card still
        // shows each issue's own zone name so the technician sees where it is.
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
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: TextStyle(fontSize: 11, color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 2. Sub-zones: Visual 2-Column Card Grid (NOT a list)
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
                              isAtRoot
                                  ? l10n.techAssignedZonesCount(displayedSubzones.length)
                                  : l10n.techSubZonesCount(displayedSubzones.length),
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
                                onTap: () => viewModel.drillDown(displayedSubzones[i]),
                              ),
                          ],
                        ),
                      ),
                    ],

                    // Empty state if root with 0 assigned zones
                    if (isAtRoot && displayedSubzones.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EmptyStateView(
                          icon: Icons.map_outlined,
                          title: l10n.techNoAssignedZones,
                          subtitle: l10n.techNoAssignedZonesSub,
                        ),
                      ),
                    ],

                    // 3. Hardware Units: Visual 2-Column Card Grid (NOT a list)
                    // Spatial Explorer: Only show devices that have unresolved issues
                    if (!isAtRoot && displayedDevices.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.build_circle_outlined,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.techUnresolvedHardwareCount(displayedDevices.length),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
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
                            for (final dev in displayedDevices)
                              ZoneDeviceCard(
                                device: dev,
                                activeIssues:
                                    issues.where((iss) => iss.deviceId == dev.id).toList(),
                                onInspectIssue: (issue) =>
                                    IssueDetailSheet.show(context, issue),
                                onUpdateIssueStatus: (issue, newStatus) {
                                  final issueId = issue.id;
                                  UpdateStatusSheet.show(
                                    context,
                                    issue: issue,
                                    initialTargetStatus: newStatus,
                                    onStatusUpdated: (status, comment, photo) async {
                                      try {
                                        await actionNotifier.updateStatus(
                                          issueId: issueId,
                                          toStatus: status,
                                          notes: comment,
                                          attachments: photo != null ? [photo] : null,
                                        );
                                        viewModel.refresh();
                                      } catch (e) {
                                        AppSnackbar.error('Failed to update status: $e');
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

                    // 4. Area-Level Incidents (Only shown if defects exist that are NOT tied to any known device above)
                    if (!isAtRoot && facilityIncidents.isNotEmpty) ...[
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
                              l10n.techFacilityIncidentsCount(facilityIncidents.length),
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
                                onTap: () => IssueDetailSheet.show(context, issue),
                                onUpdateStatus: (newStatus) {
                                  final issueId = issue.id;
                                  UpdateStatusSheet.show(
                                    context,
                                    issue: issue,
                                    initialTargetStatus: newStatus,
                                    onStatusUpdated: (status, comment, photo) async {
                                      try {
                                        await actionNotifier.updateStatus(
                                          issueId: issueId,
                                          toStatus: status,
                                          notes: comment,
                                          attachments: photo != null ? [photo] : null,
                                        );
                                        viewModel.refresh();
                                      } catch (e) {
                                        AppSnackbar.error('Failed to update status: $e');
                                        rethrow;
                                      }
                                    },
                                  );
                                },
                                onOpenTimeline: () => IssueDetailSheet.show(context, issue),
                              ),
                          ],
                        ),
                      ),
                    ],

                    // 5. Empty state if leaf zone with 0 subzones and 0 unresolved items
                    if (!isAtRoot && displayedSubzones.isEmpty && displayedDevices.isEmpty && facilityIncidents.isEmpty) ...[
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

/// Two-column card grid whose rows size to their tallest card instead of a fixed
/// aspect ratio. A fixed `childAspectRatio` GridView either overflowed the taller
/// device cards or left dead space under the shorter zone cards.
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
