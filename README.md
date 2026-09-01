# 🛠️ Fixly — Equipment & Maintenance Management System

> **Modern, role-tailored mobile application for on-site hardware inspections, daily device health checks, maintenance ticket logging, and real-time technician workflow management.**

Built with **Flutter (Material 3)**, **Riverpod 2.x**, **Dio**, and designed to integrate seamlessly with the **Node.js / Express / Prisma** backend.

---

## 📱 Table of Contents
- [Overview](#-overview)
- [Key Features by Role](#-key-features-by-role)
  - [Zone Staff & Incharge Flow](#1-zone-staff--incharge-flow)
  - [Field Technician Flow](#2-field-technician-flow)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Project Directory Structure](#-project-directory-structure)
- [Getting Started & Setup](#-getting-started--setup)
  - [Prerequisites](#prerequisites)
  - [Running the App](#running-the-app)
  - [Connecting to Local Backend over USB](#connecting-to-local-backend-over-usb)
- [Configuration & Branding](#-configuration--branding)
- [Testing & Quality Assurance](#-testing--quality-assurance)
- [Default Demo Credentials](#-default-demo-credentials)

---

## 🌟 Overview

**Fixly** simplifies physical hardware oversight across distributed commercial zones (e.g. CCTV cameras, access control turnstiles, biometric scanners, sensors, and servers).

It eliminates paper checklists and disjointed reporting by providing:
1. **Instant daily equipment checks** with one-tap status tagging.
2. **Automated fault escalation** that moves faulty hardware into maintenance.
3. **Dedicated field technician queues** with complete state-machine transitions and resolution history.

---

## 🎯 Key Features by Role

### 1. 🛡️ Zone Staff & Incharge Flow
* **Daily Hardware Checklist (`/daily-logs`)**:
  * Segmented views: **All**, **Pending**, and **Checked Today**.
  * One-tap status submission: `Working`, `Needs Attention`, or `Down / Fault`.
  * Optional inline observation notes (e.g. loose cables, dirty lens).
  * Lock-in confirmation badge when already checked today with an **Edit** option.
  * Automatic prompt to raise a maintenance ticket if hardware is marked **Down / Fault**.
* **Hardware Directory (`/devices`)**:
  * Search hardware by name, hardware type, or specific room/zone.
  * Status filter chips: `All`, `Active`, `Under Maintenance`, `Faulty`.
  * Quick-action to raise a ticket directly on any selected device.
* **Maintenance Issues Tracker (`/issues`)**:
  * Segmented tabs for **Open**, **Closed**, and **All** tickets in the user's zone.
  * Full ticket detail sheet with device metadata, technician assignment, priority, and timeline.
* **Raise Issue Bottom Sheet**:
  * Device selector (prefilled when opened from a device card).
  * **Dynamic Fault Categories**: Fetched live from `GET /hardware-types/:id` to guarantee category compatibility with the selected device type.
  * Priority selector (`Low`, `Medium`, `High`, `Critical`).
  * Detailed symptoms input and optional photo attachment preview.

---

### 2. 🔧 Field Technician Flow
* **Live KPI Metric Bar**:
  * Real-time counters for **Assigned**, **In Progress**, **On Hold**, and **Resolved** tickets.
* **Dedicated Task Queues**:
  * **Active Queue (`assigned`, `in_progress`)**: Actionable tickets requiring inspection or immediate repair.
  * **On Hold (`on_hold`)**: Work paused while awaiting spare parts or vendor approval.
  * **Resolved (`resolved`, `closed`)**: Completed repairs with full resolution notes and history.
* **Interactive Status State Machine**:
  * **Start Work**: Transitions ticket to `in_progress`.
  * **Hold**: Pauses ticket with mandatory reason/comment.
  * **Resume**: Re-activates ticket from hold to in-progress.
  * **Resolve**: Records resolution comments and automatically triggers the backend to return the device from `under_maintenance` back to `active`.
* **Search & Priority Filtering**:
  * Instant search across ticket IDs, device names, zone locations, and descriptions.
  * Priority filter chips (`All`, `Critical`, `High`, `Medium`, `Low`).

---

## 🏗️ Architecture & Tech Stack

Fixly is structured following **Clean Architecture principles** and **Feature-First modular design**:

* **Framework**: Flutter 3.x (Dart 3.x) with Material 3 styling.
* **State Management**: [Riverpod](https://riverpod.dev/) (`FutureProvider`, `NotifierProvider`, `autoDispose`) for reactive, declarative state.
* **Network & API**: [Dio](https://pub.dev/packages/dio) with:
  * Automatic `Bearer` token injection.
  * Transparent `401 Unauthorized` token refresh handling.
  * Pretty-printed HTTP request/response debugging logs.
* **Secure Storage**: `shared_preferences` / token storage abstractions.
* **Image Capture**: `image_picker` for camera and photo gallery selection.

---

## 📂 Project Directory Structure

```
lib/
├── core/
│   ├── config/              # Central application configuration & base URL
│   │   └── app_config.dart
│   ├── network/             # Dio client & auth interceptor
│   │   └── api_client.dart
│   ├── providers/           # Global Riverpod state providers
│   │   ├── auth_provider.dart
│   │   ├── daily_log_provider.dart
│   │   ├── device_provider.dart
│   │   └── issue_provider.dart
│   ├── storage/             # Token and user session persistence
│   │   └── storage_service.dart
│   ├── theme/               # Color palette, Material 3 theme & styles
│   │   └── colors.dart
│   ├── utils/               # App logger, snackbar, icon helpers
│   └── widgets/             # Shared UI components (StatusBadge, etc.)
│
├── data/
│   ├── models/              # Immutable Data Models with fromJson/toJson
│   │   ├── daily_log_model.dart
│   │   ├── dashboard_summary_model.dart
│   │   ├── device_model.dart
│   │   ├── hardware_type_model.dart
│   │   ├── issue_model.dart
│   │   ├── user_model.dart
│   │   └── zone_model.dart
│   └── repositories/        # API communication layer
│       ├── auth_repository.dart
│       ├── daily_log_repository.dart
│       ├── device_repository.dart
│       └── issue_repository.dart
│
├── features/
│   ├── auth/                # Login page & authentication flow
│   ├── home/                # Global common shell (AppBar, Sign Out, Role Router)
│   ├── staff/               # Staff Flow (Daily Checks, Hardware, Issues)
│   │   └── view/
│   │       ├── staff_home_page.dart
│   │       └── widgets/     # Issue detail sheet, Raise issue modal
│   └── technician/          # Technician Flow (Active Queue, Hold, Resolve)
│       └── view/
│           ├── technician_home_page.dart
│           └── widgets/     # Update status sheet
│
└── main.dart                # App entrypoint & ProviderScope initialization
```

---

## 🚀 Getting Started & Setup

### Prerequisites
* Flutter SDK (3.22 or higher)
* Android SDK (API 34+) or iOS Xcode
* Node.js backend running on port `3000`

### Running the App

1. **Clone the repository and install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Launch the app on a connected device or emulator**:
   ```bash
   flutter run
   ```

---

### 🔌 Connecting to Local Backend over USB

When running on a **physical Android device connected via USB**, route port `3000` so the mobile app can communicate with `localhost:3000`:

```bash
adb reverse tcp:3000 tcp:3000
```
*(If `adb` is not in your PATH, use `~/Android/Sdk/platform-tools/adb reverse tcp:3000 tcp:3000`)*

To verify the active reverse connection:
```bash
adb reverse --list
```

---

## ⚙️ Configuration & Branding

Application naming and default base URLs are centralized in [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart):

```dart
class AppConfig {
  /// Application Branding & Metadata
  static const String appName = 'Fixly';
  static const String appTagline = 'Equipment & Maintenance Management';
  static const String appVersion = '1.0.0';

  /// Default API Base URL
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
}
```

You can also pass a custom backend URL at build time:
```bash
flutter run --dart-define=API_BASE_URL=https://your-api-server.com/api/v1
```

---

## 🧪 Testing & Quality Assurance

Run the comprehensive unit, model parity, and widget test suite:

```bash
# Execute all test suites
flutter test

# Run static analysis
flutter analyze
```

---

## 🔑 Default Demo Credentials

| Role | Email | Password | Scope / Permissions |
| :--- | :--- | :--- | :--- |
| **Zone Incharge / Staff** | `ravi@cityzoo.com` | `Password123!` | Zone Daily Checks, Hardware Directory, Raise Issue |
| **Hardware Technician** | `amit@example.com` | `Password123!` | Assigned Issue Queue, Work In-Progress, Hold, Resolve |
| **Client Admin** | `admin@cityzoo.com` | `Password123!` | Full Client Scope, Dashboard Analytics |
