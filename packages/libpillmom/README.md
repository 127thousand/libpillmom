# libpillmom

A Flutter plugin for managing medications and reminders using Go+Turso/SQLite via FFI.

## Features

- Cross-platform medication management
- Reminder scheduling
- Local SQLite storage or Turso cloud database
- Native performance through Go FFI bindings

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  libpillmom:
    git:
      url: https://github.com/127thousand/libpillmom.git
      path: packages/libpillmom
```

## Usage

```dart
import 'package:libpillmom/libpillmom.dart';

void main() {
  final client = PillMomClient();

  // Initialize with local database
  client.initLocalDatabase(dbPath: 'medications.db');

  // Or initialize with Turso
  // client.initTursoDatabase(
  //   databaseUrl: 'libsql://your-database.turso.io',
  //   authToken: 'your-auth-token',
  // );

  // Create a medication
  final medication = client.createMedication(
    name: 'Aspirin',
    dosage: '100mg',
    description: 'Pain relief',
  );

  // Create a reminder
  final reminder = client.createReminder(
    medicationId: medication.id,
    time: '09:00',
    days: 'Monday,Wednesday,Friday',
  );

  // Get all medications
  final medications = client.getAllMedications();

  // Clean up
  client.closeDatabase();
}
```

## Platform Support

| Platform | Status | Architecture |
|----------|--------|-------------|
| Android  | ✅ | arm64, arm, x86_64, x86 |
| iOS      | ✅ | arm64, Simulator (arm64, x86_64) |
| macOS    | ✅ | arm64, x86_64 |
| Linux    | ✅ | arm64, x86_64 |
| Windows  | ✅ | arm64, x86_64 |

## Building from Source

To build the native libraries locally:

```bash
cd packages/libpillmom/native
./build.sh
```

This will create the appropriate library for your platform in the `lib` directory.

## Pre-built Binaries

Pre-built binaries for all supported platforms are automatically built and released via GitHub Actions. They are included in the package when you add it as a dependency.

## License

See the main repository for license information.