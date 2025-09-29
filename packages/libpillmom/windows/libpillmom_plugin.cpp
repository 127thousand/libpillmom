#include "include/libpillmom/libpillmom_plugin.h"

#include <windows.h>

namespace {

class LibPillmomPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LibPillmomPlugin();

  virtual ~LibPillmomPlugin();
};

// static
void LibPillmomPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<LibPillmomPlugin>();
  registrar->AddPlugin(std::move(plugin));
}

LibPillmomPlugin::LibPillmomPlugin() {}

LibPillmomPlugin::~LibPillmomPlugin() {}

}  // namespace

void LibPillmomPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  LibPillmomPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}