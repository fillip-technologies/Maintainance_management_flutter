import 'package:flutter/material.dart';

class HardwareIconHelper {
  /// Returns a contextual icon based on the hardware type name.
  /// Handles cameras, cables/fibers, displays/TVs, networking switches, sensors, biometrics, etc.
  static IconData getIcon(String? hardwareTypeName) {
    if (hardwareTypeName == null || hardwareTypeName.isEmpty) {
      return Icons.devices_other_rounded;
    }

    final name = hardwareTypeName.toLowerCase();

    // 1. Cameras / Vision
    if (name.contains('cam') || name.contains('cctv') || name.contains('ptz') || name.contains('bullet') || name.contains('dome')) {
      return Icons.videocam_outlined;
    }

    // 2. Cables, Optical Fibre, Wiring
    if (name.contains('fibre') || name.contains('fiber') || name.contains('cable') || name.contains('wire') || name.contains('patch')) {
      return Icons.cable_rounded;
    }

    // 3. Displays, TVs, Digital Signage, Monitors
    if (name.contains('tv') || name.contains('display') || name.contains('screen') || name.contains('monitor') || name.contains('signage')) {
      return Icons.tv_rounded;
    }

    // 4. Network, Switch, Router, Modem, AP, PoE
    if (name.contains('switch') || name.contains('router') || name.contains('modem') || name.contains('network') || name.contains('wifi') || name.contains('access point')) {
      return Icons.router_rounded;
    }

    // 5. Sensors (Smoke, Motion, Air Quality, Temp, Thermostat)
    if (name.contains('sensor') || name.contains('smoke') || name.contains('thermostat') || name.contains('temp') || name.contains('motion') || name.contains('detector')) {
      return Icons.sensors_rounded;
    }

    // 6. Access Control, Biometrics, RFID, Keypad
    if (name.contains('biometric') || name.contains('scanner') || name.contains('fingerprint') || name.contains('access') || name.contains('rfid') || name.contains('keypad')) {
      return Icons.fingerprint_rounded;
    }

    // 7. Audio, PA Speakers, Intercom, Mic
    if (name.contains('speaker') || name.contains('pa ') || name.contains('audio') || name.contains('intercom') || name.contains('mic')) {
      return Icons.volume_up_rounded;
    }

    // 8. Fire Alarms, Emergency, Sirens
    if (name.contains('fire') || name.contains('alarm') || name.contains('siren')) {
      return Icons.local_fire_department_rounded;
    }

    // 9. Power, UPS, Battery, Solar
    if (name.contains('power') || name.contains('solar') || name.contains('ups') || name.contains('battery')) {
      return Icons.battery_charging_full_rounded;
    }

    // Generic Default Hardware Icon
    return Icons.devices_other_rounded;
  }
}
