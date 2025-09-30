# LibPillmom Example

This example demonstrates how to use the libpillmom Flutter plugin with different database connection modes.

## Setup

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Configure your database connection in `.env`.

## Connection Modes

LibPillmom supports multiple database connection modes:

### 1. In-Memory Database
- No persistence (data is lost when the app closes)
- Good for testing or temporary data
```env
DATABASE_TYPE=memory
```

### 2. Local SQLite Database (Default)
- Stores data in a local SQLite file
- Persistent storage on the device
```env
DATABASE_TYPE=local
DATABASE_PATH=example.db
```

### 3. Remote Turso Database
- Connects to a remote Turso database
- Data is stored in the cloud
- Requires URL and authentication token
```env
DATABASE_TYPE=remote
TURSO_DATABASE_URL=libsql://your-database.turso.io
TURSO_AUTH_TOKEN=your-auth-token-here
```

### 4. Embedded Replica
- Local SQLite database that syncs with a remote Turso database
- Provides offline capability with cloud sync
- Note: Currently falls back to remote connection due to FFI issues
```env
DATABASE_TYPE=replica
REPLICA_PATH=local_replica.db
TURSO_DATABASE_URL=libsql://your-database.turso.io
TURSO_AUTH_TOKEN=your-auth-token-here
SYNC_PERIOD=60  # Optional, sync period in seconds
```

## Running the Example

```bash
dart example.dart
```

The example will:
1. Initialize the database connection based on your `.env` configuration
2. Create sample medications and reminders
3. Demonstrate CRUD operations
4. Show how to fetch and update data
5. Handle database syncing (for remote/replica modes)

## Using in Your Code

```dart
import 'package:libpillmom/libpillmom.dart';

void main() async {
  final client = PillMomClient();

  // Choose your connection mode:

  // In-memory
  await client.openInMemory();

  // Local SQLite
  await client.openLocal('my_database.db');

  // Remote Turso
  await client.openRemote(url, authToken);

  // Embedded Replica
  await client.openEmbeddedReplica(
    'local_replica.db',
    url,
    authToken,
    syncPeriod: Duration(minutes: 1),
  );

  // Use the client...
  final medications = await client.getAllMedications();
}
```