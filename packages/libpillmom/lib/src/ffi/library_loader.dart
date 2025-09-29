import 'dart:ffi';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Loads the appropriate native library based on the current platform
class LibraryLoader {
  static DynamicLibrary? _library;

  static DynamicLibrary get library {
    _library ??= _loadLibrary();
    return _library!;
  }

  static DynamicLibrary _loadLibrary() {
    final libraryPath = _getLibraryPath();

    if (libraryPath != null && File(libraryPath).existsSync()) {
      return DynamicLibrary.open(libraryPath);
    }

    // Fallback to process or executable lookup
    return _loadLibraryFallback();
  }

  static String? _getLibraryPath() {
    // First, try to load from the package's platform-specific directories
    final packageRoot = _findPackageRoot();
    if (packageRoot != null) {
      final platformDir = _getPlatformDirectory();
      if (platformDir != null) {
        final platformPath = path.join(packageRoot, platformDir);
        final libPath = _getPlatformLibraryPath(platformPath);
        if (libPath != null && File(libPath).existsSync()) {
          return libPath;
        }
      }
    }

    // Try loading from the current directory (for development)
    final currentDirPath = _getPlatformLibraryPath(Directory.current.path);
    if (currentDirPath != null && File(currentDirPath).existsSync()) {
      return currentDirPath;
    }

    // Try loading from native directory (for local builds)
    final nativeDir = path.join(Directory.current.path, 'native');
    final nativePath = _getPlatformLibraryPath(nativeDir);
    if (nativePath != null && File(nativePath).existsSync()) {
      return nativePath;
    }

    return null;
  }

  static String? _getPlatformDirectory() {
    if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return null;
  }

  static String? _getPlatformLibraryPath(String directory) {
    if (Platform.isMacOS) {
      // In platform directories, libraries use generic names
      return path.join(directory, 'libpillmom.dylib');
    } else if (Platform.isLinux) {
      return path.join(directory, 'libpillmom.so');
    } else if (Platform.isWindows) {
      return path.join(directory, 'libpillmom.dll');
    } else if (Platform.isAndroid) {
      // Android libraries are typically loaded from the app's lib directory
      return path.join(directory, 'libpillmom.so');
    } else if (Platform.isIOS) {
      // iOS uses frameworks
      return path.join(directory, 'libpillmom.framework', 'libpillmom');
    }
    return null;
  }


  static DynamicLibrary _loadLibraryFallback() {
    if (Platform.isMacOS || Platform.isLinux) {
      // Try to load from process (useful for Flutter apps)
      try {
        return DynamicLibrary.process();
      } catch (_) {}

      // Try to load from executable
      try {
        return DynamicLibrary.executable();
      } catch (_) {}
    }

    // Platform-specific fallbacks
    if (Platform.isMacOS) {
      return DynamicLibrary.open('libpillmom.dylib');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libpillmom.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('libpillmom.dll');
    } else if (Platform.isAndroid) {
      return DynamicLibrary.open('libpillmom.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    }

    throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
  }

  static String? _findPackageRoot() {
    // Try to find the package root by looking for pubspec.yaml
    Directory current = Directory.current;

    while (current.path != current.parent.path) {
      final pubspec = File(path.join(current.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        final content = pubspec.readAsStringSync();
        if (content.contains('name: libpillmom')) {
          return current.path;
        }
      }

      // Check if we're in packages/libpillmom
      if (current.path.endsWith('packages/libpillmom') ||
          current.path.endsWith('packages${Platform.pathSeparator}libpillmom')) {
        return current.path;
      }

      current = current.parent;
    }

    return null;
  }
}