Pod::Spec.new do |s|
  s.name             = 'libpillmom'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter plugin for managing medications and reminders'
  s.description      = <<-DESC
A Flutter plugin for managing medications and reminders using Go+Turso/SQLite via FFI.
                       DESC
  s.homepage         = 'https://github.com/127thousand/libpillmom'
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

  # Use XCFramework
  s.vendored_frameworks = 'libpillmom.xcframework'
end