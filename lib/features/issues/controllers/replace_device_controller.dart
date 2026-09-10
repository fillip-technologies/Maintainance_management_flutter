import '../../devices/devices.dart';
import '../../../l10n/app_localizations.dart';
import 'replace_device_state.dart';

class ReplaceDeviceController {
  final void Function(ReplaceDeviceState state) onStateChanged;

  ReplaceDeviceState _state;
  ReplaceDeviceState get state => _state;

  ReplaceDeviceController({
    ReplaceDeviceState initialState = const ReplaceDeviceState(),
    required this.onStateChanged,
  }) : _state = initialState;

  void _update(ReplaceDeviceState newState) {
    _state = newState;
    onStateChanged(_state);
  }

  void setReason(DecommissionReason reason) {
    _update(_state.copyWith(selectedReason: reason));
  }

  void setReplacementChoice(ReplacementChoice choice) {
    if (choice == ReplacementChoice.none) {
      _update(_state.copyWith(
        replacementChoice: choice,
        clearSelectedSpareDevice: true,
      ));
    } else {
      _update(_state.copyWith(replacementChoice: choice));
    }
  }

  void setSelectedSpareDevice(DeviceModel? device) {
    _update(_state.copyWith(selectedSpareDevice: device));
  }

  void setNotes(String notes) {
    _update(_state.copyWith(notes: notes));
  }

  void setSearchQuery(String query) {
    _update(_state.copyWith(searchQuery: query));
  }

  void setSubmitting(bool isSubmitting) {
    _update(_state.copyWith(isSubmitting: isSubmitting));
  }

  static String getReasonLabel(DecommissionReason reason, AppLocalizations l10n) {
    return switch (reason) {
      DecommissionReason.physicalDamage => l10n.reasonPhysicalDamage,
      DecommissionReason.burntWater => l10n.reasonBurntWater,
      DecommissionReason.unrepairable => l10n.reasonUnrepairable,
      DecommissionReason.obsolete => l10n.reasonObsolete,
    };
  }

  static String buildFullComment({
    required DecommissionReason reason,
    required ReplacementChoice choice,
    required String userNotes,
    DeviceModel? selectedSpare,
    required AppLocalizations l10n,
  }) {
    final reasonText = getReasonLabel(reason, l10n);
    final trimmedNotes = userNotes.trim();
    final baseNote = trimmedNotes.isNotEmpty ? '$reasonText. $trimmedNotes' : reasonText;

    final replacementText = switch (choice) {
      ReplacementChoice.inStock =>
        'Installed in-stock spare unit: ${selectedSpare?.name} (${selectedSpare?.code.isNotEmpty == true ? selectedSpare?.code : selectedSpare?.id}).',
      ReplacementChoice.newDevice => 'Installed new hardware unit.',
      ReplacementChoice.none => 'No replacement installed; slot left vacant.',
    };

    return '[HARDWARE DECOMMISSIONED - ${reason.name.toUpperCase()}] $baseNote. $replacementText';
  }

  static List<DeviceModel> filterSpares({
    required List<DeviceModel> spares,
    required String searchQuery,
  }) {
    if (searchQuery.isEmpty) return spares;
    final q = searchQuery.toLowerCase();
    return spares.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.code.toLowerCase().contains(q) ||
          s.hardwareTypeName.toLowerCase().contains(q);
    }).toList();
  }
}
