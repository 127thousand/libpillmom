# LibPillMom

A Dart library for managing medications and reminders using Turso database via Go FFI bridge with GORM.

## Features

- Full CRUD operations for medications and reminders
- Support for both local SQLite and Turso cloud database
- FFI bridge between Dart and Go for high performance
- GORM-based database operations with automatic migrations
- Type-safe Dart API with model classes

## Project Structure

```
libpillmom/
├── go.mod                     # Go module configuration
├── ffi_bridge.go             # C exports for FFI bridge
├── build.sh                  # Build script for shared library
├── database/
│   └── connection.go         # Database connection management
├── models/
│   └── models.go            # GORM models for Medication and Reminder
├── repository/
│   ├── medication_repository.go  # Medication CRUD operations
│   └── reminder_repository.go    # Reminder CRUD operations
└── dart/
    ├── pubspec.yaml
    ├── lib/
    │   ├── pillmom.dart     # Main library export
    │   └── src/
    │       ├── ffi/
    │       │   └── bindings.dart     # FFI bindings
    │       ├── models/
    │       │   └── medication.dart   # Dart model classes
    │       └── pillmom_client.dart   # Main client API
    └── example/
        └── example.dart      # Usage example
```

## Prerequisites

1. **Go** (1.21 or later) - Required to build the shared library
2. **Dart** (3.0 or later) - For the Dart client
3. **Turso CLI** (optional) - If using Turso cloud database

## Building the Go Shared Library

First, install Go dependencies:

```bash
go mod download
```

Then build the shared library:

```bash
chmod +x build.sh
./build.sh
```

This will create:
- `libpillmom.dylib` on macOS
- `libpillmom.so` on Linux
- `libpillmom.dll` on Windows

## Using the Dart Library

### Installation

Navigate to the dart directory and install dependencies:

```bash
cd dart
dart pub get
```

### Basic Usage

```dart
import 'package:pillmom/pillmom.dart';

void main() async {
  final client = PillMomClient();

  // Initialize local database
  client.initLocalDatabase(dbPath: 'pillmom.db');

  // Or use Turso cloud database
  // client.initTursoDatabase(
  //   databaseUrl: 'libsql://your-database.turso.io',
  //   authToken: 'your-auth-token',
  // );

  // Create a medication
  final medicationId = client.createMedication(
    name: 'Aspirin',
    dosage: '100mg',
    description: 'Pain reliever',
  );

  // Create a reminder
  if (medicationId != null) {
    client.createReminder(
      medicationId: medicationId,
      time: '08:00',
      days: 'Daily',
    );
  }

  // Get all medications
  final medications = client.getAllMedications();
  for (final med in medications) {
    print('${med.name}: ${med.dosage}');
  }

  // Close database
  client.closeDatabase();
}
```

### API Reference

#### Database Initialization

```dart
// Local SQLite database
bool initLocalDatabase({String dbPath = 'pillmom.db'})

// Turso cloud database
bool initTursoDatabase({required String databaseUrl, required String authToken})

// Close connection
bool closeDatabase()
```

#### Medication Operations

```dart
// Create
int? createMedication({
  required String name,
  required String dosage,
  String description = '',
})

// Read
Medication? getMedication(int id)
List<Medication> getAllMedications()

// Update
bool updateMedication({
  required int id,
  required String name,
  required String dosage,
  String description = '',
})

// Delete
bool deleteMedication(int id)
```

#### Reminder Operations

```dart
// Create
int? createReminder({
  required int medicationId,
  required String time,     // Format: "HH:MM"
  String days = 'Daily',     // e.g., "Daily", "Mon,Wed,Fri"
})

// Read
Reminder? getReminder(int id)
List<Reminder> getRemindersByMedication(int medicationId)
List<Reminder> getAllReminders()
List<Reminder> getActiveReminders()

// Update
bool updateReminder({
  required int id,
  required String time,
  required String days,
  bool isActive = true,
})

// Delete
bool deleteReminder(int id)
```

## Models

### Medication
- `id`: Unique identifier
- `name`: Medication name
- `dosage`: Dosage information
- `description`: Additional description
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp
- `reminders`: Associated reminders

### Reminder
- `id`: Unique identifier
- `medicationId`: Associated medication
- `time`: Reminder time (HH:MM format)
- `days`: Days to remind (e.g., "Daily", "Mon,Wed,Fri")
- `isActive`: Whether reminder is active
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

## Running the Example

```bash
# Build the Go library first
./build.sh

# Run the Dart example
cd dart
dart run example/example.dart
```

## Using with Turso

1. Create a Turso database:
```bash
turso db create pill-reminder
```

2. Get your database URL and auth token:
```bash
turso db show pill-reminder --url
turso db tokens create pill-reminder
```

3. Use in your Dart code:
```dart
client.initTursoDatabase(
  databaseUrl: 'libsql://your-database.turso.io',
  authToken: 'your-auth-token',
);
```

## Development

### Adding New Features

1. Add new models in `models/models.go`
2. Create repository functions in `repository/`
3. Export C functions in `ffi_bridge.go`
4. Add Dart bindings in `dart/lib/src/ffi/bindings.dart`
5. Create wrapper methods in `dart/lib/src/pillmom_client.dart`
6. Rebuild the shared library with `./build.sh`

### Testing

Run tests in the Dart package:
```bash
cd dart
dart test
```

## License

MIT