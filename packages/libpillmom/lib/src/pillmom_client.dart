import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'ffi/bindings.dart';
import 'ffi/library_loader.dart';
import 'models/medication.dart';

class PillMomClient {
  late final PillMomBindings _bindings;
  static PillMomClient? _instance;

  PillMomClient._internal() {
    _bindings = PillMomBindings(LibraryLoader.library);
  }

  factory PillMomClient() {
    _instance ??= PillMomClient._internal();
    return _instance!;
  }

  /// Initialize local database
  bool initLocalDatabase({String dbPath = 'pillmom.db'}) {
    final pathPtr = dbPath.toNativeUtf8();
    try {
      final result = _bindings.initDatabase(pathPtr);
      return result == 0;
    } finally {
      malloc.free(pathPtr);
    }
  }

  /// Initialize Turso database
  bool initTursoDatabase({required String databaseUrl, required String authToken}) {
    final urlPtr = databaseUrl.toNativeUtf8();
    final tokenPtr = authToken.toNativeUtf8();
    try {
      final result = _bindings.initTursoDatabase(urlPtr, tokenPtr);
      return result == 0;
    } finally {
      malloc.free(urlPtr);
      malloc.free(tokenPtr);
    }
  }

  /// Close database connection
  bool closeDatabase() {
    final result = _bindings.closeDatabase();
    return result == 0;
  }

  /// Create a new medication
  int? createMedication({
    required String name,
    required String dosage,
    String description = '',
  }) {
    final namePtr = name.toNativeUtf8();
    final dosagePtr = dosage.toNativeUtf8();
    final descPtr = description.toNativeUtf8();

    try {
      final result = _bindings.createMedication(namePtr, dosagePtr, descPtr);
      return result >= 0 ? result : null;
    } finally {
      malloc.free(namePtr);
      malloc.free(dosagePtr);
      malloc.free(descPtr);
    }
  }

  /// Get medication by ID
  Medication? getMedication(int id) {
    final jsonPtr = _bindings.getMedication(id);
    if (jsonPtr == nullptr) return null;

    try {
      final jsonStr = jsonPtr.toDartString();
      final json = jsonDecode(jsonStr);
      return Medication.fromJson(json);
    } finally {
      _bindings.freeString(jsonPtr);
    }
  }

  /// Get all medications
  List<Medication> getAllMedications() {
    final jsonPtr = _bindings.getAllMedications();
    if (jsonPtr == nullptr) return [];

    try {
      final jsonStr = jsonPtr.toDartString();
      final jsonList = jsonDecode(jsonStr) as List;
      return jsonList.map((json) => Medication.fromJson(json)).toList();
    } finally {
      _bindings.freeString(jsonPtr);
    }
  }

  /// Update medication
  bool updateMedication({
    required int id,
    required String name,
    required String dosage,
    String description = '',
  }) {
    final namePtr = name.toNativeUtf8();
    final dosagePtr = dosage.toNativeUtf8();
    final descPtr = description.toNativeUtf8();

    try {
      final result = _bindings.updateMedication(id, namePtr, dosagePtr, descPtr);
      return result == 0;
    } finally {
      malloc.free(namePtr);
      malloc.free(dosagePtr);
      malloc.free(descPtr);
    }
  }

  /// Delete medication
  bool deleteMedication(int id) {
    final result = _bindings.deleteMedication(id);
    return result == 0;
  }

  /// Create a new reminder
  int? createReminder({
    required int medicationId,
    required String time,
    String days = 'Daily',
  }) {
    final timePtr = time.toNativeUtf8();
    final daysPtr = days.toNativeUtf8();

    try {
      final result = _bindings.createReminder(medicationId, timePtr, daysPtr);
      return result >= 0 ? result : null;
    } finally {
      malloc.free(timePtr);
      malloc.free(daysPtr);
    }
  }

  /// Get reminder by ID
  Reminder? getReminder(int id) {
    final jsonPtr = _bindings.getReminder(id);
    if (jsonPtr == nullptr) return null;

    try {
      final jsonStr = jsonPtr.toDartString();
      final json = jsonDecode(jsonStr);
      return Reminder.fromJson(json);
    } finally {
      _bindings.freeString(jsonPtr);
    }
  }

  /// Get reminders by medication ID
  List<Reminder> getRemindersByMedication(int medicationId) {
    final jsonPtr = _bindings.getRemindersByMedication(medicationId);
    if (jsonPtr == nullptr) return [];

    try {
      final jsonStr = jsonPtr.toDartString();
      final jsonList = jsonDecode(jsonStr) as List;
      return jsonList.map((json) => Reminder.fromJson(json)).toList();
    } finally {
      _bindings.freeString(jsonPtr);
    }
  }

  /// Get all reminders
  List<Reminder> getAllReminders() {
    final jsonPtr = _bindings.getAllReminders();
    if (jsonPtr == nullptr) return [];

    try {
      final jsonStr = jsonPtr.toDartString();
      final jsonList = jsonDecode(jsonStr) as List;
      return jsonList.map((json) => Reminder.fromJson(json)).toList();
    } finally {
      _bindings.freeString(jsonPtr);
    }
  }

  /// Get active reminders
  List<Reminder> getActiveReminders() {
    final jsonPtr = _bindings.getActiveReminders();
    if (jsonPtr == nullptr) return [];

    try {
      final jsonStr = jsonPtr.toDartString();
      final jsonList = jsonDecode(jsonStr) as List;
      return jsonList.map((json) => Reminder.fromJson(json)).toList();
    } finally {
      _bindings.freeString(jsonPtr);
    }
  }

  /// Update reminder
  bool updateReminder({
    required int id,
    required String time,
    required String days,
    bool isActive = true,
  }) {
    final timePtr = time.toNativeUtf8();
    final daysPtr = days.toNativeUtf8();

    try {
      final result = _bindings.updateReminder(
        id,
        timePtr,
        daysPtr,
        isActive ? 1 : 0,
      );
      return result == 0;
    } finally {
      malloc.free(timePtr);
      malloc.free(daysPtr);
    }
  }

  /// Delete reminder
  bool deleteReminder(int id) {
    final result = _bindings.deleteReminder(id);
    return result == 0;
  }
}