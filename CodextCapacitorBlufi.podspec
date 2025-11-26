require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'CodextCapacitorBlufi'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Sources/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.exclude_files = 'ios/Sources/**/openssl/**/*'
  s.public_header_files = 'ios/Sources/**/*.h'
  s.preserve_paths = 'ios/Sources/BlufiPlugin/**/*'
  s.header_mappings_dir = 'ios/Sources/BlufiPlugin'
  s.ios.deployment_target = '14.0'
  s.dependency 'Capacitor'
  s.dependency 'OpenSSL-Universal'
  s.swift_version = '5.1'
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/ios/Sources/BlufiPlugin" "${PODS_TARGET_SRCROOT}/ios/Sources/BlufiPlugin/BlufiLibrary" "${PODS_TARGET_SRCROOT}/ios/Sources/BlufiPlugin/ESPAPPResources"'
  }
end
