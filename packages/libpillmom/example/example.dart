import 'dart:io';
import 'package:libpillmom/libpillmom.dart';

/// Simple .env file loader
Map<String, String> loadEnv(String path) {
  final env = <String, String>{};

  try {
    final file = File(path);
    if (!file.existsSync()) {
      print('Warning: $path not found. Using defaults.');
      return env;
    }

    final lines = file.readAsLinesSync();
    for (final line in lines) {
      // Skip comments and empty lines
      if (line.trim().isEmpty || line.trim().startsWith('#')) continue;

      // Parse KEY=VALUE
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        env[key] = value;
      }
    }
  } catch (e) {
    print('Error loading .env: $e');
  }

  return env;
}

void main() async {
  final client = PillMomClient();

  // Load configuration from .env file
  final env = loadEnv('.env');

  // Check if .env exists, otherwise use example values
  if (env.isEmpty) {
    print('No .env file found. Copy .env.example to .env and configure it.');
    print('Using local database for this demo...\n');
    env['DATABASE_TYPE'] = 'local';
    env['DATABASE_PATH'] = 'example.db';
  }

  // Initialize database based on configuration
  final dbType = env['DATABASE_TYPE'] ?? 'local';

  try {
    switch (dbType) {
      case 'memory':
        print('Initializing in-memory database (no persistence)...');
        await client.openInMemory();
        break;

      case 'local':
        final dbPath = env['DATABASE_PATH'] ?? 'example.db';
        print('Initializing local database: $dbPath');
        await client.openLocal(dbPath);
        break;

      case 'remote':
      case 'turso':
        final databaseUrl = env['TURSO_DATABASE_URL'];
        final authToken = env['TURSO_AUTH_TOKEN'];

        if (databaseUrl == null || authToken == null) {
          print('Error: TURSO_DATABASE_URL and TURSO_AUTH_TOKEN must be set in .env');
          return;
        }

        print('Initializing remote Turso database...');
        print('URL: $databaseUrl\n');
        await client.openRemote(databaseUrl, authToken);
        break;

      case 'replica':
        final databaseUrl = env['TURSO_DATABASE_URL'];
        final authToken = env['TURSO_AUTH_TOKEN'];
        final replicaPath = env['REPLICA_PATH'] ?? 'local_replica.db';
        final syncPeriod = env['SYNC_PERIOD'] != null
            ? Duration(seconds: int.parse(env['SYNC_PERIOD']!))
            : Duration(seconds: 60);

        if (databaseUrl == null || authToken == null) {
          print('Error: TURSO_DATABASE_URL and TURSO_AUTH_TOKEN must be set in .env');
          return;
        }

        print('Initializing embedded replica...');
        print('Local path: $replicaPath');
        print('Remote URL: $databaseUrl');
        print('Sync period: ${syncPeriod.inSeconds} seconds\n');
        await client.openEmbeddedReplica(
          replicaPath,
          databaseUrl,
          authToken,
          syncPeriod: syncPeriod,
        );
        break;

      default:
        print('Unknown database type: $dbType');
        print('Valid types: memory, local, remote, turso, replica');
        return;
    }

    print('Database initialized successfully!\n');

    print('\n--- Creating Medications ---\n');

    // Create medications
    final aspirinId = await client.createMedication(
      name: 'Aspirin',
      dosage: '100mg',
      description: 'Pain reliever and blood thinner',
    );
    print('Created Aspirin with ID: $aspirinId');

    final vitaminDId = await client.createMedication(
      name: 'Vitamin D',
      dosage: '1000 IU',
      description: 'Vitamin D supplement',
    );
    print('Created Vitamin D with ID: $vitaminDId');

    final omeprazoleId = await client.createMedication(
      name: 'Omeprazole',
      dosage: '20mg',
      description: 'Proton pump inhibitor for acid reflux',
    );
    print('Created Omeprazole with ID: $omeprazoleId');

    print('\n--- Setting Up Reminders ---\n');

    // Create reminders for medications
    final reminder1Id = await client.createReminder(
      medicationId: aspirinId,
      time: '08:00',
      days: 'Daily',
    );
    print('Created daily reminder for Aspirin at 08:00, ID: $reminder1Id');

    final reminder2Id = await client.createReminder(
      medicationId: vitaminDId,
      time: '09:00',
      days: 'Mon,Wed,Fri',
    );
    print('Created MWF reminder for Vitamin D at 09:00, ID: $reminder2Id');

    final reminder3Id = await client.createReminder(
      medicationId: omeprazoleId,
      time: '07:00',
      days: 'Daily',
    );
    print('Created morning reminder for Omeprazole at 07:00, ID: $reminder3Id');

    final reminder4Id = await client.createReminder(
      medicationId: omeprazoleId,
      time: '19:00',
      days: 'Daily',
    );
    print('Created evening reminder for Omeprazole at 19:00, ID: $reminder4Id');

    print('\n--- Fetching All Medications ---');

    // Get all medications with their reminders
    final medications = await client.getAllMedications();
    for (final med in medications) {
      print('${med.name} (${med.dosage}): ${med.description}');

      // Reminders are included in the medication object
      if (med.reminders.isNotEmpty) {
        for (final reminder in med.reminders) {
          print('  - Reminder: ${reminder.time} on ${reminder.days} (Active: ${reminder.isActive})');
        }
      }
    }

    print('\n--- Fetching Active Reminders ---');

    // Get all active reminders
    final activeReminders = await client.getActiveReminders();
    print('Total active reminders: ${activeReminders.length}');
    for (final reminder in activeReminders) {
      print('- ${reminder.time} on ${reminder.days} for medication ID ${reminder.medicationId}');
    }

    print('\n--- Updating a Medication ---\n');

    // Update a medication - need to get the full object first
    final medsForUpdate = await client.getAllMedications();
    final aspirinMed = medsForUpdate.firstWhere((m) => m.id == aspirinId);

    // Update the medication with new dosage
    final updatedMed = Medication(
      id: aspirinMed.id,
      name: aspirinMed.name,
      dosage: '75mg', // Changed dosage
      description: 'Low-dose aspirin for heart health',
      createdAt: aspirinMed.createdAt,
      updatedAt: aspirinMed.updatedAt,
      deletedAt: aspirinMed.deletedAt,
      reminders: aspirinMed.reminders,
    );

    final updateSuccess = await client.updateMedication(updatedMed);
    print('Updated Aspirin dosage: $updateSuccess');

    // Verify the update
    final updatedMeds = await client.getAllMedications();
    final verifyMed = updatedMeds.firstWhere((m) => m.id == aspirinId);
    print('Updated medication: ${verifyMed.name} - ${verifyMed.dosage}');

    print('\n--- Deactivating a Reminder ---\n');

    // Deactivate the first reminder
    if (activeReminders.isNotEmpty) {
      final firstReminder = activeReminders.first;
      final updatedReminder = Reminder(
        id: firstReminder.id,
        medicationId: firstReminder.medicationId,
        time: firstReminder.time,
        days: firstReminder.days,
        isActive: false, // Deactivate
        createdAt: firstReminder.createdAt,
        updatedAt: firstReminder.updatedAt,
        deletedAt: firstReminder.deletedAt,
      );

      final reminderUpdateSuccess = await client.updateReminder(updatedReminder);
      print('Deactivated reminder: $reminderUpdateSuccess');
    }

    print('\n--- Syncing Database (if applicable) ---\n');

    // Sync database if using remote or replica
    if (dbType == 'remote' || dbType == 'turso' || dbType == 'replica') {
      try {
        await client.syncDatabase();
        print('Database synced successfully');
      } catch (e) {
        print('Sync operation completed or not applicable: $e');
      }
    } else {
      print('Sync not needed for $dbType database');
    }

    print('\n--- Cleaning Up (Optional) ---\n');

    // Delete a medication (uncomment to test)
    // final deleteSuccess = await client.deleteMedication(vitaminDId);
    // print('Deleted Vitamin D: $deleteSuccess');

    // Delete a reminder (uncomment to test)
    // if (activeReminders.isNotEmpty) {
    //   final deleteReminderSuccess = await client.deleteReminder(activeReminders.first.id!);
    //   print('Deleted reminder: $deleteReminderSuccess');
    // }

    // Close database connection
    await client.closeDatabase();
    print('Database connection closed.');

  } catch (e) {
    print('Error: $e');
    print('\nFailed to initialize database');
    print('If using Turso, make sure your URL and auth token are correct.');
    print('If using local database, make sure the path is writable.');
  }
}