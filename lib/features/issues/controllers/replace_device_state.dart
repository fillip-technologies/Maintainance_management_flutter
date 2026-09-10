import '../../devices/devices.dart';

enum DecommissionReason {
  physicalDamage('physical_damage'),
  burntWater('burnt_water'),
  unrepairable('unrepairable'),
  obsolete('obsolete');

  final String value;
  const DecommissionReason(this.value);
}

enum ReplacementChoice {
  inStock,
  newDevice,
  none,
}

class ReplaceDeviceState {
  final DecommissionReason selectedReason;
  final ReplacementChoice replacementChoice;
  final DeviceModel? selectedSpareDevice;
  final String notes;
  final String searchQuery;
  final bool isSubmitting;

  const ReplaceDeviceState({
    this.selectedReason = DecommissionReason.physicalDamage,
    this.replacementChoice = ReplacementChoice.none,
    this.selectedSpareDevice,
    this.notes = '',
    this.searchQuery = '',
    this.isSubmitting = false,
  });

  ReplaceDeviceState copyWith({
    DecommissionReason? selectedReason,
    ReplacementChoice? replacementChoice,
    DeviceModel? selectedSpareDevice,
    bool clearSelectedSpareDevice = false,
    String? notes,
    String? searchQuery,
    bool? isSubmitting,
  }) {
    return ReplaceDeviceState(
      selectedReason: selectedReason ?? this.selectedReason,
      replacementChoice: replacementChoice ?? this.replacementChoice,
      selectedSpareDevice: clearSelectedSpareDevice
          ? null
          : (selectedSpareDevice ?? this.selectedSpareDevice),
      notes: notes ?? this.notes,
      searchQuery: searchQuery ?? this.searchQuery,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
