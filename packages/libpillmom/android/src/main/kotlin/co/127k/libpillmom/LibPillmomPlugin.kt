package co.127k.libpillmom

import io.flutter.embedding.engine.plugins.FlutterPlugin

class LibPillmomPlugin: FlutterPlugin {
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // No-op: This is an FFI plugin, so we don't need to register a method channel
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    // No-op
  }
}