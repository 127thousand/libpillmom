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
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Add the static libraries for device and simulator
  s.vendored_libraries = 'libpillmom.a', 'libpillmom_simulator.a'

  # Configure which library to use based on the SDK
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '$(inherited) -force_load $(PODS_TARGET_SRCROOT)/libpillmom.a',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited) -force_load $(PODS_TARGET_SRCROOT)/libpillmom_simulator.a'
  }
end