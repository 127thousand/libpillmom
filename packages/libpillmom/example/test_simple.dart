import 'package:libpillmom/libpillmom.dart';

void main() async {
  print('Testing libpillmom...');

  final client = PillMomClient();

  try {
    print('Initializing local database...');
    await client.initLocalDatabase('test.db');
    print('Database initialized!');

    print('\nCreating a medication...');
    final id = await client.createMedication(
      name: 'Test Med',
      dosage: '10mg',
      description: 'Test medication',
    );
    print('Created medication with ID: $id');

    print('\nFetching all medications...');
    final meds = await client.getAllMedications();
    print('Found ${meds.length} medications');

    for (final med in meds) {
      print('- ${med.name} (${med.dosage})');
    }

    print('\nClosing database...');
    await client.closeDatabase();
    print('Done!');
  } catch (e) {
    print('Error: $e');
  }
}