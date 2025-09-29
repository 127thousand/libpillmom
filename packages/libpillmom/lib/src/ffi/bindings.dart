import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef InitDatabaseC = Int32 Function(Pointer<Utf8> dbPath);
typedef InitDatabaseDart = int Function(Pointer<Utf8> dbPath);

typedef InitTursoDatabaseC = Int32 Function(
    Pointer<Utf8> databaseURL, Pointer<Utf8> authToken);
typedef InitTursoDatabaseDart = int Function(
    Pointer<Utf8> databaseURL, Pointer<Utf8> authToken);

typedef CloseDatabaseC = Int32 Function();
typedef CloseDatabaseDart = int Function();

typedef CreateMedicationC = Int32 Function(
    Pointer<Utf8> name, Pointer<Utf8> dosage, Pointer<Utf8> description);
typedef CreateMedicationDart = int Function(
    Pointer<Utf8> name, Pointer<Utf8> dosage, Pointer<Utf8> description);

typedef GetMedicationC = Pointer<Utf8> Function(Uint32 id);
typedef GetMedicationDart = Pointer<Utf8> Function(int id);

typedef GetAllMedicationsC = Pointer<Utf8> Function();
typedef GetAllMedicationsDart = Pointer<Utf8> Function();

typedef UpdateMedicationC = Int32 Function(Uint32 id, Pointer<Utf8> name,
    Pointer<Utf8> dosage, Pointer<Utf8> description);
typedef UpdateMedicationDart = int Function(
    int id, Pointer<Utf8> name, Pointer<Utf8> dosage, Pointer<Utf8> description);

typedef DeleteMedicationC = Int32 Function(Uint32 id);
typedef DeleteMedicationDart = int Function(int id);

typedef CreateReminderC = Int32 Function(
    Uint32 medicationID, Pointer<Utf8> time, Pointer<Utf8> days);
typedef CreateReminderDart = int Function(
    int medicationID, Pointer<Utf8> time, Pointer<Utf8> days);

typedef GetReminderC = Pointer<Utf8> Function(Uint32 id);
typedef GetReminderDart = Pointer<Utf8> Function(int id);

typedef GetRemindersByMedicationC = Pointer<Utf8> Function(Uint32 medicationID);
typedef GetRemindersByMedicationDart = Pointer<Utf8> Function(int medicationID);

typedef GetAllRemindersC = Pointer<Utf8> Function();
typedef GetAllRemindersDart = Pointer<Utf8> Function();

typedef GetActiveRemindersC = Pointer<Utf8> Function();
typedef GetActiveRemindersDart = Pointer<Utf8> Function();

typedef UpdateReminderC = Int32 Function(
    Uint32 id, Pointer<Utf8> time, Pointer<Utf8> days, Int32 isActive);
typedef UpdateReminderDart = int Function(
    int id, Pointer<Utf8> time, Pointer<Utf8> days, int isActive);

typedef DeleteReminderC = Int32 Function(Uint32 id);
typedef DeleteReminderDart = int Function(int id);

typedef FreeStringC = Void Function(Pointer<Utf8> str);
typedef FreeStringDart = void Function(Pointer<Utf8> str);

class PillMomBindings {
  final DynamicLibrary _lib;

  late final InitDatabaseDart initDatabase;
  late final InitTursoDatabaseDart initTursoDatabase;
  late final CloseDatabaseDart closeDatabase;
  late final CreateMedicationDart createMedication;
  late final GetMedicationDart getMedication;
  late final GetAllMedicationsDart getAllMedications;
  late final UpdateMedicationDart updateMedication;
  late final DeleteMedicationDart deleteMedication;
  late final CreateReminderDart createReminder;
  late final GetReminderDart getReminder;
  late final GetRemindersByMedicationDart getRemindersByMedication;
  late final GetAllRemindersDart getAllReminders;
  late final GetActiveRemindersDart getActiveReminders;
  late final UpdateReminderDart updateReminder;
  late final DeleteReminderDart deleteReminder;
  late final FreeStringDart freeString;

  PillMomBindings(this._lib) {
    initDatabase = _lib
        .lookup<NativeFunction<InitDatabaseC>>('InitDatabase')
        .asFunction<InitDatabaseDart>();

    initTursoDatabase = _lib
        .lookup<NativeFunction<InitTursoDatabaseC>>('InitTursoDatabase')
        .asFunction<InitTursoDatabaseDart>();

    closeDatabase = _lib
        .lookup<NativeFunction<CloseDatabaseC>>('CloseDatabase')
        .asFunction<CloseDatabaseDart>();

    createMedication = _lib
        .lookup<NativeFunction<CreateMedicationC>>('CreateMedication')
        .asFunction<CreateMedicationDart>();

    getMedication = _lib
        .lookup<NativeFunction<GetMedicationC>>('GetMedication')
        .asFunction<GetMedicationDart>();

    getAllMedications = _lib
        .lookup<NativeFunction<GetAllMedicationsC>>('GetAllMedications')
        .asFunction<GetAllMedicationsDart>();

    updateMedication = _lib
        .lookup<NativeFunction<UpdateMedicationC>>('UpdateMedication')
        .asFunction<UpdateMedicationDart>();

    deleteMedication = _lib
        .lookup<NativeFunction<DeleteMedicationC>>('DeleteMedication')
        .asFunction<DeleteMedicationDart>();

    createReminder = _lib
        .lookup<NativeFunction<CreateReminderC>>('CreateReminder')
        .asFunction<CreateReminderDart>();

    getReminder = _lib
        .lookup<NativeFunction<GetReminderC>>('GetReminder')
        .asFunction<GetReminderDart>();

    getRemindersByMedication = _lib
        .lookup<NativeFunction<GetRemindersByMedicationC>>(
            'GetRemindersByMedication')
        .asFunction<GetRemindersByMedicationDart>();

    getAllReminders = _lib
        .lookup<NativeFunction<GetAllRemindersC>>('GetAllReminders')
        .asFunction<GetAllRemindersDart>();

    getActiveReminders = _lib
        .lookup<NativeFunction<GetActiveRemindersC>>('GetActiveReminders')
        .asFunction<GetActiveRemindersDart>();

    updateReminder = _lib
        .lookup<NativeFunction<UpdateReminderC>>('UpdateReminder')
        .asFunction<UpdateReminderDart>();

    deleteReminder = _lib
        .lookup<NativeFunction<DeleteReminderC>>('DeleteReminder')
        .asFunction<DeleteReminderDart>();

    freeString = _lib
        .lookup<NativeFunction<FreeStringC>>('FreeString')
        .asFunction<FreeStringDart>();
  }
}