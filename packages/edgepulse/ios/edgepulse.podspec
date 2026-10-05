Pod::Spec.new do |s|
  s.name             = 'edgepulse'
  s.version          = '0.2.0'
  s.summary          = 'Runtime observability plugin for EdgePulse on-device AI.'
  s.description      = <<-DESC
    EdgePulse Flutter plugin — captures real memory (RSS), thermal state,
    battery level, and CPU utilisation from iOS devices via platform channels.
    Use with edgepulse_core for complete on-device AI observability.
  DESC
  s.homepage         = 'https://github.com/assassinaj602/edgepulse'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'EdgePulse' => 'assassinaj602@github.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
