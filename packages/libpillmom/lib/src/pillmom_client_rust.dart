import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'ffi/bindings_rust.dart';
import 'ffi/library_loader.dart';
import 'models/medication.dart';
import 'models/reminder.dart';

class PillMomClient {
  late final PillMomRustBindings _bindings;
  static PillMomClient? _instance;

  PillMomClient._internal() {
    final dylib = LibraryLoader.loadLibrary();
    _bindings = PillMomRustBindings(dylib);
  }

  factory PillMomClient() {
    _instance ??= PillMomClient._internal();
    return _instance!;
  }

  String _callRustFunction(Pointer<Utf8> Function() fn) {
    final resultPtr = fn();
    final result = resultPtr.toDartString();
    _bindings.freeString(resultPtr);
    return result;
  }

  String _callRustFunctionWithParam(
      Pointer<Utf8> Function(Pointer<Utf8>) fn, String param) {
    final paramPtr = param.toNativeUtf8();
    final resultPtr = fn(paramPtr);
    final result = resultPtr.toDartString();
    malloc.free(paramPtr);
    _bindings.freeString(resultPtr);
    return result;
  }

  String _callRustFunctionWithTwoParams(
      Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>) fn,
      String param1,
      String param2) {
    final param1Ptr = param1.toNativeUtf8();
    final param2Ptr = param2.toNativeUtf8();
    final resultPtr = fn(param1Ptr, param2Ptr);
    final result = resultPtr.toDartString();
    malloc.free(param1Ptr);
    malloc.free(param2Ptr);
    _bindings.freeString(resultPtr);
    return result;
  }

  String _callRustFunctionWithIntParam(
      Pointer<Utf8> Function(int) fn, int param) {
    final resultPtr = fn(param);
    final result = resultPtr.toDartString();
    _bindings.freeString(resultPtr);
    return result;
  }

  Future<void> initTursoDatabase(String url, String authToken) async {
    final result = _callRustFunctionWithTwoParams(
        _bindings.initTursoDb, url, authToken);
    final json = jsonDecode(result);
    if (json['success'] != true) {
      throw Exception(json['error'] ?? 'Failed to initialize Turso database');
    }
  }

  Future<void> initLocalDatabase([String? dbPath]) async {
    final path = dbPath ?? 'pillmom.db';
    final result = _callRustFunctionWithParam(_bindings.initLocalDb, path);
    final json = jsonDecode(result);
    if (json['success'] != true) {
      throw Exception(json['error'] ?? 'Failed to initialize local database');
    }
  }

  Future<void> syncDatabase() async {
    final result = _callRustFunction(_bindings.syncDatabase);
    final json = jsonDecode(result);
    if (json['success'] != true) {
      throw Exception(json['error'] ?? 'Failed to sync database');
    }
  }

  Future<void> closeDatabase() async {
    final result = _callRustFunction(_bindings.closeDatabase);
    final json = jsonDecode(result);
    if (json['success'] != true) {
      throw Exception(json['error'] ?? 'Failed to close database');
    }
  }

  Future<int> createMedication({
    required String name,
    required String dosage,
    String description = '',
  }) async {
    final medication = {
      'name': name,
      'dosage': dosage,
      'description': description,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'deleted_at': null,
      'reminders': [],
    };

    final result = _callRustFunctionWithParam(
        _bindings.createMedication, jsonEncode(medication));
    final json = jsonDecode(result);

    if (json['success'] == true) {
      return json['id'];
    } else {
      throw Exception(json['error'] ?? 'Failed to create medication');
    }
  }

  Future<List<Medication>> getAllMedications() async {
    final result = _callRustFunction(_bindings.getAllMedications);
    final json = jsonDecode(result);

    if (json['success'] == true) {
      final List<dynamic> medicationsJson = json['medications'];
      return medicationsJson
          .map((m) => Medication.fromJson(m as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(json['error'] ?? 'Failed to get medications');
    }
  }

  Future<bool> updateMedication(Medication medication) async {
    final medicationJson = medication.toJson();

    final result = _callRustFunctionWithParam(
        _bindings.updateMedication, jsonEncode(medicationJson));
    final json = jsonDecode(result);

    if (json['success'] == true) {
      return json['updated'] == true;
    } else {
      throw Exception(json['error'] ?? 'Failed to update medication');
    }
  }

  Future<bool> deleteMedication(int id) async {
    final result = _callRustFunctionWithIntParam(_bindings.deleteMedication, id);
    final json = jsonDecode(result);

    if (json['success'] == true) {
      return json['deleted'] == true;
    } else {
      throw Exception(json['error'] ?? 'Failed to delete medication');
    }
  }

  Future<int> createReminder({
    required int medicationId,
    required String time,
    required String days,
    bool isActive = true,
  }) async {
    final reminder = {
      'medication_id': medicationId,
      'time': time,
      'days': days,
      'is_active': isActive,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'deleted_at': null,
    };

    final result = _callRustFunctionWithParam(
        _bindings.createReminder, jsonEncode(reminder));
    final json = jsonDecode(result);

    if (json['success'] == true) {
      return json['id'];
    } else {
      throw Exception(json['error'] ?? 'Failed to create reminder');
    }
  }

  Future<List<Reminder>> getActiveReminders() async {
    final result = _callRustFunction(_bindings.getActiveReminders);
    final json = jsonDecode(result);

    if (json['success'] == true) {
      final List<dynamic> remindersJson = json['reminders'];
      return remindersJson
          .map((r) => Reminder.fromJson(r as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(json['error'] ?? 'Failed to get active reminders');
    }
  }

  Future<bool> updateReminder(Reminder reminder) async {
    final reminderJson = reminder.toJson();

    final result = _callRustFunctionWithParam(
        _bindings.updateReminder, jsonEncode(reminderJson));
    final json = jsonDecode(result);

    if (json['success'] == true) {
      return json['updated'] == true;
    } else {
      throw Exception(json['error'] ?? 'Failed to update reminder');
    }
  }

  Future<bool> deleteReminder(int id) async {
    final result = _callRustFunctionWithIntParam(_bindings.deleteReminder, id);
    final json = jsonDecode(result);

    if (json['success'] == true) {
      return json['deleted'] == true;
    } else {
      throw Exception(json['error'] ?? 'Failed to delete reminder');
    }
  }
}