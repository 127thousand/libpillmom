import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'generated/api.dart';
import 'generated/models.dart';
import 'generated/frb_generated.dart';
import 'dart:io' show Platform;
import 'package:path/path.dart' as path;

export 'generated/models.dart';

class PillMomClient {
  PillMomApi? _api;
  static PillMomClient? _instance;
  static bool _initialized = false;

  PillMomClient._internal();

  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      // Get the proper library path
      String libraryPath;
      if (Platform.isMacOS) {
        // For macOS, look for the library relative to the package
        final packageRoot = path.dirname(path.dirname(Platform.script.path));
        libraryPath = path.join(packageRoot, 'macos', 'libpillmom.dylib');
      } else if (Platform.isLinux) {
        libraryPath = 'libpillmom.so';
      } else if (Platform.isWindows) {
        libraryPath = 'libpillmom.dll';
      } else {
        libraryPath = 'libpillmom';
      }

      // Initialize the Rust library with explicit path
      await RustLib.init(
        externalLibrary: ExternalLibrary.open(libraryPath),
      );
      _initialized = true;
    }
  }

  factory PillMomClient() {
    _instance ??= PillMomClient._internal();
    return _instance!;
  }

  // ===== New Connection Methods =====

  /// Connect to an in-memory database (no persistence)
  Future<void> openInMemory() async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    await _api!.openInMemory();
  }

  /// Connect to a local SQLite database file
  Future<void> openLocal(String path) async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    await _api!.openLocal(path: path);
  }

  /// Connect to a remote Turso database
  Future<void> openRemote(String url, String authToken) async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    await _api!.openRemote(url: url, authToken: authToken);
  }

  /// Connect to an embedded replica (local SQLite that syncs with remote)
  /// Note: Currently falls back to remote connection due to FFI issues
  Future<void> openEmbeddedReplica(
    String path,
    String url,
    String authToken, {
    Duration? syncPeriod,
  }) async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    await _api!.openEmbeddedReplica(
      path: path,
      url: url,
      authToken: authToken,
      syncPeriod: syncPeriod?.inSeconds.toDouble(),
    );
  }

  // ===== Legacy Methods (for backward compatibility) =====

  Future<void> initTursoDatabase(String url, String authToken) async {
    await openRemote(url, authToken);
  }

  Future<void> initLocalDatabase([String? dbPath]) async {
    final path = dbPath ?? 'pillmom.db';
    await openLocal(path);
  }

  Future<void> syncDatabase() async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    await _api!.syncDatabase();
  }

  Future<void> closeDatabase() async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    await _api!.closeDatabase();
  }

  // Medication operations
  Future<int> createMedication({
    required String name,
    required String dosage,
    String description = '',
  }) async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    return await _api!.createMedication(
      name: name,
      dosage: dosage,
      description: description,
    );
  }

  Future<List<Medication>> getAllMedications() async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    return await _api!.getAllMedications();
  }

  Future<bool> updateMedication(Medication medication) async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    return await _api!.updateMedication(medication: medication);
  }

  Future<bool> deleteMedication(int id) async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    return await _api!.deleteMedication(id: id);
  }

  // Reminder operations
  Future<int> createReminder({
    required int medicationId,
    required String time,
    required String days,
    bool isActive = true,
  }) async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    return await _api!.createReminder(
      medicationId: medicationId,
      time: time,
      days: days,
      isActive: isActive,
    );
  }

  Future<List<Reminder>> getActiveReminders() async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    return await _api!.getActiveReminders();
  }

  Future<bool> updateReminder(Reminder reminder) async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    return await _api!.updateReminder(reminder: reminder);
  }

  Future<bool> deleteReminder(int id) async {
    await _ensureInitialized();
    _api ??= PillMomApi();
    return await _api!.deleteReminder(id: id);
  }
}