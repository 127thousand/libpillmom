#include "include/libpillmom/libpillmom_plugin.h"

#include <flutter_linux/flutter_linux.h>

#define LIBPILLMOM_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), libpillmom_plugin_get_type(), \
                               LibPillmomPlugin))

struct _LibPillmomPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(LibPillmomPlugin, libpillmom_plugin, g_object_get_type())

static void libpillmom_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(libpillmom_plugin_parent_class)->dispose(object);
}

static void libpillmom_plugin_class_init(LibPillmomPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = libpillmom_plugin_dispose;
}

static void libpillmom_plugin_init(LibPillmomPlugin* self) {}

void libpillmom_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  LibPillmomPlugin* plugin = LIBPILLMOM_PLUGIN(
      g_object_new(libpillmom_plugin_get_type(), nullptr));

  g_object_unref(plugin);
}