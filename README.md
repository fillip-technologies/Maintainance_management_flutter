# 🛠️ Fixly — Equipment & Maintenance Management System

> **Production-ready, feature-driven mobile application for on-site hardware inspections, daily device health checks, maintenance defect ticket management, and real-time technician workflows.**

Built with **Flutter (Material 3)**, **Riverpod 2.x**, **Dio**, **Socket.IO Client**, and designed to integrate seamlessly with the **Node.js / Express / PostgreSQL (Prisma)** backend.

---

## 📱 Table of Contents
- [Overview](#-overview)
- [Key Features by Role](#-key-features-by-role)
  - [Zone Staff & Incharge Flow](#1-zone-staff--incharge-flow)
  - [Field Technician Flow](#2-field-technician-flow)
  - [Cross-Role & Real-Time Capabilities](#3-cross-role--real-time-capabilities)
- [Architecture & Design System](#-architecture--design-system)
  - [Feature-Driven MVVM Pattern](#feature-driven-mvvm-pattern)
  - [Coding Standards & Guidelines](#coding-standards--guidelines)
- [Project Directory Structure](#-project-directory-structure)
- [Getting Started & Setup](#-getting-started--setup)
  - [Prerequisites](#prerequisites)
  - [Running the App](#running-the-app)
  - [Connecting to Local Backend over USB / Android](#connecting-to-local-backend-over-usb--android)
- [Configuration & Localization](#-configuration--localization)
- [Testing & Quality Assurance](#-testing--quality-assurance)
- [Default Test Credentials](#-default-test-credentials)

---

## 🌟 Overview

**Fixly** simplifies physical equipment and hardware oversight across distributed commercial zones (e.g. CCTV cameras, access control turnstiles, biometric scanners, automated gates, power units, and sensors).

It eliminates paper logs and communication delays by providing:
1. **Daily Device Health Audits** with one-tap status tagging (`Working`, `Needs Attention`, `Down / Faulty`).
2. **Instant Defect Escalation** that automatically transitions malfunctioning hardware into maintenance and dispatches tickets.
3. **Live Technician Queues** with state-machine workflow actions (`Start Work`, `Hold`, `Resume`, `Resolve`).
4. **Bilingual Localization** (English & Hindi) with instant persistence.
5. **Real-Time Synchronisation** powered by Socket.IO for live ticket events, status transitions, and notification toasts.

---

## 🎯 Key Features by Role

### 1. 🛡️ Zone Staff & Incharge Flow
* **Daily Hardware Checklist (`/daily-logs`)**:
  * Segmented filtering: **All**, **Pending**, and **Done Today**.
  * One-tap status submission: `Working`, `Needs Attention`, or `Not Working`.
  * Inline observation notes with editing and cancellation support.
  * Auto-escalation prompt: Marking a device as `Not Working` prompts the user to raise a maintenance defect ticket immediately.
* **Hardware Directory (`/devices`)**:
  * Real-time search by equipment name, hardware type, zone, or specific location.
  * Status filtering: `All`, `Active`, `Maintenance`, `Faulty`, `In Stock`, `Removed`.
  * Direct one-tap ticket creation from any hardware tile.
* **Maintenance Issues Tracker (`/issues`)**:
  * Segmented tabs: **Open**, **Closed**, and **All** tickets scoped to the user's assigned zone.
  * Comprehensive ticket detail view with timeline event history, device specs, technician assignment, and priority badges.
* **Raise Issue Bottom Sheet**:
  * Dynamic fault categories fetched per hardware type (`GET /hardware-types/:id`) ensuring schema parity.
  * Priority selector (`Critical`, `High`, `Medium`, `Low`).
  * Structured symptom description and resolution requirement inputs.

---

### 2. 🔧 Field Technician Flow
* **Live KPI Metric Bar**:
  * Real-time metric counters for **Total**, **Open / Active**, **On Hold**, and **Resolved** tickets.
* **Dedicated Task Queues**:
  * **Active Queue**: Open, assigned, in-progress, and reopened tickets.
  * **On Hold**: Paused tasks awaiting parts, vendor approvals, or access.
  * **Resolved History**: Successfully inspected and repaired hardware.
* **Interactive Status State Machine**:
  * **Start Work**: Transitions ticket from `open`/`assigned` ➔ `in_progress`.
  * **Hold**: Places work on hold with required reason / comment.
  * **Resume**: Re-activates ticket to `in_progress`.
  * **Resolve**: Records resolution comments; self-healing auto-transitions move `open` tickets through `in_progress` to `resolved` to uphold backend validation.
* **Search & Priority Filtering**:
  * Multi-field query filtering across ticket ID, title, device name, and zone.
  * Filter chips for instant priority narrowing.

---

### 3. ⚡ Cross-Role & Real-Time Capabilities
* **Socket.IO Event Sync**:
  * Live ticket broadcast listeners (`issue:created`, `issue:updated`, `log:submitted`).
  * Non-intrusive in-app banner toasts (`RealtimeToastHelper`) when new tickets arrive or work is resolved.
  * Live WebSocket connection health pill (`Online`, `Connecting`, `Offline`) in the app bar.
* **Profile & Preferences (`/profile`)**:
  * User profile details (Role, Assigned Zone Scope, Organization ID, User ID with one-tap copy).
  * System info (App name, version, production environment).
  * Sign out with safe confirmation dialog and secure token destruction.

---

## 🏗️ Architecture & Design System

### Feature-Driven MVVM Pattern
Fixly adheres strictly to a **Feature-Driven MVVM (Model-View-ViewModel)** layered architecture. Each feature is self-contained with its own models, repositories, viewmodels, views, and public API barrel file:

```
lib/features/<feature_name>/
├── models/         # Immutable data transfer objects and explicit state models
├── repositories/   # Typed API clients and network boundaries
├── viewmodels/     # Riverpod Notifiers/Providers encapsulating business decisions
├── views/          # Declarative UI layouts, pages, and modular widgets
└── <feature>.dart  # Public feature barrel exporting domain interfaces
```

### Coding Standards & Guidelines (`.agents/AGENT.md`)
* **Early Returns (Rule 1)**: Eliminates deep nested `if/else` ladders via early guard clauses.
* **Separation of Concerns (Rule 2 & 5)**: Views only render state and forward user intentions. Decisions, computations (e.g. ticket filtering, KPI aggregations), and repository calls belong in ViewModels.
* **Domain-Specific Naming (Rule 3)**: Domain-driven names (`TechnicianQueueState`, `StaffChecklistViewModel`) over generic technical containers.
* **Explicit State Modeling (Rule 4)**: Complex UI states (filters, draft notes, submission sets) are encapsulated in immutable classes.
* **Predictable Error Boundary (Rule 6)**: Centralized error handling in `AppException` with stable machine-readable codes (`AppErrorCode`).

---

## 📂 Project Directory Structure

```
lib/
├── core/                                   # Shared application-wide infrastructure
│   ├── config/                             # App branding, environment variables & base URLs
│   │   └── app_config.dart
│   ├── errors/                             # Typed error domain boundary & error codes
│   │   └── app_exception.dart
│   ├── network/                            # HTTP & WebSocket communications
│   │   ├── api_client.dart                 # Dio client with auto-refresh token interceptor
│   │   └── socket_service.dart             # Socket.IO client with JWT handshake
│   ├── storage/                            # Secure local session & token storage
│   │   └── storage_service.dart
│   ├── theme/                              # Design tokens, color schemes & Material 3 styling
│   │   └── colors.dart
│   ├── utils/                              # Logging, snackbars, icon mapping, JWT helper
│   │   ├── app_logger.dart
│   │   ├── app_snackbar.dart
│   │   ├── hardware_icon_helper.dart
│   │   ├── jwt_helper.dart
│   │   └── realtime_toast_helper.dart
│   └── widgets/                            # Reusable universal UI widgets
│       ├── connection_status_pill.dart
│       ├── language_segmented_control.dart
│       ├── language_switcher_button.dart
│       └── status_badge.dart
│
├── features/                               # Feature-Driven MVVM modules
│   ├── auth/                               # User authentication & session management
│   │   ├── models/user_model.dart
│   │   ├── repositories/auth_repository.dart
│   │   ├── viewmodels/auth_viewmodel.dart
│   │   ├── views/login_page.dart
│   │   └── auth.dart
│   │
│   ├── daily_logs/                         # Daily device health checks & summaries
│   │   ├── models/daily_log_model.dart
│   │   ├── models/dashboard_summary_model.dart
│   │   ├── repositories/daily_log_repository.dart
│   │   ├── viewmodels/daily_log_viewmodel.dart
│   │   └── daily_logs.dart
│   │
│   ├── devices/                            # Hardware catalogue, types & zones
│   │   ├── models/device_model.dart
│   │   ├── models/hardware_type_model.dart
│   │   ├── models/zone_model.dart
│   │   ├── repositories/device_repository.dart
│   │   ├── viewmodels/device_viewmodel.dart
│   │   ├── views/helpers/hardware_icon_helper.dart
│   │   └── devices.dart
│   │
│   ├── home/                               # Common application shell & role dispatcher
│   │   ├── views/global_home_page.dart
│   │   └── home.dart
│   │
│   ├── issues/                             # Defect tickets, timeline & status sheets
│   │   ├── models/issue_model.dart
│   │   ├── repositories/issue_repository.dart
│   │   ├── viewmodels/issue_action_viewmodel.dart
│   │   ├── viewmodels/issue_query_viewmodel.dart
│   │   ├── views/issue_detail_sheet.dart
│   │   ├── views/raise_issue_sheet.dart
│   │   ├── views/replace_device_sheet.dart
│   │   ├── views/update_status_sheet.dart
│   │   ├── views/widgets/issue_card.dart
│   │   ├── views/widgets/issue_timeline_view.dart
│   │   └── issues.dart
│   │
│   ├── profile/                            # User profile, language & session
│   │   ├── models/profile_state.dart
│   │   ├── viewmodels/locale_viewmodel.dart
│   │   ├── viewmodels/profile_viewmodel.dart
│   │   ├── views/profile_page.dart
│   │   ├── views/widgets/profile_header_card.dart
│   │   ├── views/widgets/profile_info_tile.dart
│   │   └── profile.dart
│   │
│   ├── realtime/                           # Realtime Socket.IO subscriptions & notifications
│   │   ├── models/socket_event_model.dart
│   │   ├── viewmodels/socket_viewmodel.dart
│   │   ├── views/connection_status_pill.dart
│   │   ├── views/realtime_toast_helper.dart
│   │   └── realtime.dart
│   │
│   ├── staff/                              # Zone staff dashboard & checklist tab
│   │   ├── models/staff_checklist_state.dart
│   │   ├── viewmodels/staff_checklist_viewmodel.dart
│   │   ├── viewmodels/staff_dashboard_viewmodel.dart
│   │   ├── views/staff_home_page.dart
│   │   ├── views/widgets/staff_daily_checklist_tab.dart
│   │   ├── views/widgets/staff_device_check_card.dart
│   │   ├── views/widgets/staff_devices_directory_tab.dart
│   │   ├── views/widgets/staff_issues_tracker_tab.dart
│   │   ├── views/widgets/staff_kpi_bar.dart
│   │   └── staff.dart
│   │
│   └── technician/                         # Technician queue, KPI & workflow actions
│       ├── models/technician_queue_filter.dart
│       ├── models/technician_queue_state.dart
│       ├── viewmodels/technician_action_viewmodel.dart
│       ├── viewmodels/technician_kpi_viewmodel.dart
│       ├── viewmodels/technician_queue_viewmodel.dart
│       ├── views/technician_home_page.dart
│       ├── views/widgets/technician_issue_card.dart
│       ├── views/widgets/technician_issue_list.dart
│       ├── views/widgets/technician_kpi_bar.dart
│       ├── views/widgets/technician_search_filter_bar.dart
│       └── technician.dart
│
├── l10n/                                   # Localization files (English & Hindi)
│   ├── app_en.arb
│   └── app_hi.arb
│
└── main.dart                               # Application entrypoint & ProviderScope
```

---

## 🚀 Getting Started & Setup

### Prerequisites
* **Flutter SDK**: `3.22.0` or higher
* **Dart SDK**: `3.4.0` or higher
* **Target Platforms**: Android (API 24+) or iOS (iOS 13+)
* **Backend Server**: Fixly backend running on port `3000`

### Running the App

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on connected emulator or device**:
   ```bash
   flutter run
   ```

---

### 🔌 Connecting to Local Backend over USB / Android

When testing on a **physical Android device connected via USB cable**, forward port `3000` using Android Debug Bridge (`adb`):

```bash
adb reverse tcp:3000 tcp:3000
```
*(If `adb` is not in your global path, use `~/Android/Sdk/platform-tools/adb reverse tcp:3000 tcp:3000`)*

Verify the port forwarding:
```bash
adb reverse --list
# Should display: host-17 tcp:3000 tcp:3000
```

---

## ⚙️ Configuration & Localization

### API Base URL Configuration
The default backend URL is defined in [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart):

```dart
static const String defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/api/v1',
);
```

You can point to a staging or production server at build/run time:
```bash
flutter run --dart-define=API_BASE_URL=https://api.fixly.example.com/api/v1
```

### Bilingual Localization
The app supports English (`en`) and Hindi (`hi`) dynamically:
* Generated via `flutter_localizations` from `.arb` files in `lib/l10n/`.
* Switchable with the top-right floating language toggle on the Login page or AppBar button.
* Preference is automatically persisted in local storage via `LocaleNotifier`.

---

## 🧪 Testing & Quality Assurance

Run the test suite and static analysis:

```bash
# Run all unit, widget, and model parity tests
flutter test

# Run static analysis (strict lint rules)
flutter analyze
```

**Quality Status**:
- `flutter analyze`: **0 errors, 0 warnings** (`No issues found!`)
- `flutter test`: **15/15 tests passing (100%)**

---

## 🔑 Default Test Credentials

| Role | Email | Password | Assigned Scope / Permissions |
| :--- | :--- | :--- | :--- |
| **Zone Staff / Incharge** | `ravi@cityzoo.com` | `Password123!` | Scoped to assigned zone; daily audits, hardware directory, defect tickets |
| **Hardware Technician** | `amit@example.com` | `Password123!` | Organization-wide assigned queue; start work, hold, resume, resolve |
| **Client Administrator** | `admin@cityzoo.com` | `Password123!` | Organization-wide administration scope |
