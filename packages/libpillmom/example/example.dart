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
  bool initialized = false;

  if (dbType == 'turso') {
    final databaseUrl = env['TURSO_DATABASE_URL'];
    final authToken = env['TURSO_AUTH_TOKEN'];

    if (databaseUrl == null || authToken == null) {
      print('Error: TURSO_DATABASE_URL and TURSO_AUTH_TOKEN must be set in .env');
      return;
    }

    print('Initializing Turso database...');
    print('URL: $databaseUrl');
    initialized = client.initTursoDatabase(
      databaseUrl: databaseUrl,
      authToken: authToken,
    );
  } else {
    final dbPath = env['DATABASE_PATH'] ?? 'example.db';
    print('Initializing local database: $dbPath');
    initialized = client.initLocalDatabase(dbPath: dbPath);
  }

  if (!initialized) {
    print('Failed to initialize database');
    return;
  }

  print('Database initialized successfully!\n');

  print('\n--- Creating Medications ---');

  // Create medications
  final aspirinId = client.createMedication(
    name: 'Aspirin',
    dosage: '100mg',
    description: 'Pain reliever and blood thinner',
  );
  print('Created Aspirin with ID: $aspirinId');

  final vitaminDId = client.createMedication(
    name: 'Vitamin D',
    dosage: '1000 IU',
    description: 'Vitamin D supplement',
  );
  print('Created Vitamin D with ID: $vitaminDId');

  final omeprazoleId = client.createMedication(
    name: 'Omeprazole',
    dosage: '20mg',
    description: 'Proton pump inhibitor for acid reflux',
  );
  print('Created Omeprazole with ID: $omeprazoleId');

  print('\n--- Setting Up Reminders ---');

  // Create reminders for medications
  if (aspirinId != null) {
    final reminderId = client.createReminder(
      medicationId: aspirinId,
      time: '08:00',
      days: 'Daily',
    );
    print('Created daily reminder for Aspirin at 08:00, ID: $reminderId');
  }

  if (vitaminDId != null) {
    final reminderId = client.createReminder(
      medicationId: vitaminDId,
      time: '09:00',
      days: 'Mon,Wed,Fri',
    );
    print('Created MWF reminder for Vitamin D at 09:00, ID: $reminderId');
  }

  if (omeprazoleId != null) {
    final reminder1 = client.createReminder(
      medicationId: omeprazoleId,
      time: '07:00',
      days: 'Daily',
    );
    print('Created morning reminder for Omeprazole at 07:00, ID: $reminder1');

    final reminder2 = client.createReminder(
      medicationId: omeprazoleId,
      time: '19:00',
      days: 'Daily',
    );
    print('Created evening reminder for Omeprazole at 19:00, ID: $reminder2');
  }

  print('\n--- Fetching All Medications ---');

  // Get all medications with their reminders
  final medications = client.getAllMedications();
  for (final med in medications) {
    print('${med.name} (${med.dosage}): ${med.description}');

    // Get reminders for this medication
    final reminders = client.getRemindersByMedication(med.id!);
    for (final reminder in reminders) {
      print('  - Reminder: ${reminder.time} on ${reminder.days} (Active: ${reminder.isActive})');
    }
  }

  print('\n--- Fetching Active Reminders ---');

  // Get all active reminders
  final activeReminders = client.getActiveReminders();
  print('Total active reminders: ${activeReminders.length}');
  for (final reminder in activeReminders) {
    print('- ${reminder.time} on ${reminder.days} for medication ID ${reminder.medicationId}');
  }

  print('\n--- Updating a Medication ---');

  // Update a medication
  if (aspirinId != null) {
    final success = client.updateMedication(
      id: aspirinId,
      name: 'Aspirin',
      dosage: '75mg',  // Changed dosage
      description: 'Low-dose aspirin for heart health',
    );
    print('Updated Aspirin dosage: $success');

    // Fetch updated medication
    final updatedMed = client.getMedication(aspirinId);
    if (updatedMed != null) {
      print('Updated medication: ${updatedMed.name} - ${updatedMed.dosage}');
    }
  }

  print('\n--- Deactivating a Reminder ---');

  // Get and deactivate a reminder
  final allReminders = client.getAllReminders();
  if (allReminders.isNotEmpty) {
    final firstReminder = allReminders.first;
    final success = client.updateReminder(
      id: firstReminder.id!,
      time: firstReminder.time,
      days: firstReminder.days,
      isActive: false,
    );
    print('Deactivated reminder: $success');
  }

  print('\n--- Cleaning Up (Optional) ---');

  // Delete a medication (this will cascade delete its reminders in the database)
  // Uncomment to test deletion
  // if (vitaminDId != null) {
  //   final success = client.deleteMedication(vitaminDId);
  //   print('Deleted Vitamin D: $success');
  // }

  // Close database connection
  client.closeDatabase();
  print('\nDatabase connection closed.');
}