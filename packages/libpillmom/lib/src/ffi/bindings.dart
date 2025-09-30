import 'dart:ffi';
import 'package:ffi/ffi.dart';

// All Rust functions return JSON strings (as char*)
typedef RustFunctionC = Pointer<Utf8> Function(Pointer<Utf8> param);
typedef RustFunctionDart = Pointer<Utf8> Function(Pointer<Utf8> param);

typedef RustFunctionTwoParamsC = Pointer<Utf8> Function(
    Pointer<Utf8> param1, Pointer<Utf8> param2);
typedef RustFunctionTwoParamsDart = Pointer<Utf8> Function(
    Pointer<Utf8> param1, Pointer<Utf8> param2);

typedef RustFunctionNoParamsC = Pointer<Utf8> Function();
typedef RustFunctionNoParamsDart = Pointer<Utf8> Function();

typedef RustFunctionIntParamC = Pointer<Utf8> Function(Int64 param);
typedef RustFunctionIntParamDart = Pointer<Utf8> Function(int param);

typedef FreeStringC = Void Function(Pointer<Utf8> str);
typedef FreeStringDart = void Function(Pointer<Utf8> str);

class PillMomBindings {
  final DynamicLibrary _lib;

  late final RustFunctionTwoParamsDart initTursoDb;
  late final RustFunctionDart initLocalDb;
  late final RustFunctionNoParamsDart syncDatabase;
  late final RustFunctionNoParamsDart closeDatabase;
  late final RustFunctionDart createMedication;
  late final RustFunctionNoParamsDart getAllMedications;
  late final RustFunctionDart updateMedication;
  late final RustFunctionIntParamDart deleteMedication;
  late final RustFunctionDart createReminder;
  late final RustFunctionNoParamsDart getActiveReminders;
  late final RustFunctionDart updateReminder;
  late final RustFunctionIntParamDart deleteReminder;
  late final FreeStringDart freeString;

  PillMomBindings(this._lib) {
    initTursoDb = _lib
        .lookup<NativeFunction<RustFunctionTwoParamsC>>('init_turso_db')
        .asFunction<RustFunctionTwoParamsDart>();

    initLocalDb = _lib
        .lookup<NativeFunction<RustFunctionC>>('init_local_db')
        .asFunction<RustFunctionDart>();

    syncDatabase = _lib
        .lookup<NativeFunction<RustFunctionNoParamsC>>('sync_database')
        .asFunction<RustFunctionNoParamsDart>();

    closeDatabase = _lib
        .lookup<NativeFunction<RustFunctionNoParamsC>>('close_database')
        .asFunction<RustFunctionNoParamsDart>();

    createMedication = _lib
        .lookup<NativeFunction<RustFunctionC>>('create_medication')
        .asFunction<RustFunctionDart>();

    getAllMedications = _lib
        .lookup<NativeFunction<RustFunctionNoParamsC>>('get_all_medications')
        .asFunction<RustFunctionNoParamsDart>();

    updateMedication = _lib
        .lookup<NativeFunction<RustFunctionC>>('update_medication')
        .asFunction<RustFunctionDart>();

    deleteMedication = _lib
        .lookup<NativeFunction<RustFunctionIntParamC>>('delete_medication')
        .asFunction<RustFunctionIntParamDart>();

    createReminder = _lib
        .lookup<NativeFunction<RustFunctionC>>('create_reminder')
        .asFunction<RustFunctionDart>();

    getActiveReminders = _lib
        .lookup<NativeFunction<RustFunctionNoParamsC>>('get_active_reminders')
        .asFunction<RustFunctionNoParamsDart>();

    updateReminder = _lib
        .lookup<NativeFunction<RustFunctionC>>('update_reminder')
        .asFunction<RustFunctionDart>();

    deleteReminder = _lib
        .lookup<NativeFunction<RustFunctionIntParamC>>('delete_reminder')
        .asFunction<RustFunctionIntParamDart>();

    freeString = _lib
        .lookup<NativeFunction<FreeStringC>>('free_string')
        .asFunction<FreeStringDart>();
  }
}