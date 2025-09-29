Pod::Spec.new do |s|
  s.name             = 'libpillmom'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter plugin for managing medications and reminders'
  s.description      = <<-DESC
A Flutter plugin for managing medications and reminders using Go+Turso/SQLite via FFI.
                       DESC
  s.homepage         = 'https://github.com/ostrearium/libpillmom'
  s.license          = { :file => '../LICENSE' }
  s.author           = { '127k' => 'support@127k.co' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  # Add the universal dynamic library
  s.vendored_libraries = 'libpillmom.dylib'
end