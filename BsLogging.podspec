Pod::Spec.new do |s|
  s.name         = 'BsLogging'
  s.version      = '1.0.0'
  s.summary      = 'A Logging API for Swift.'
  s.homepage     = 'https://github.com/BaldStudio/BsLogging.git'
  s.license      = { :type => 'MIT', :text => 'LICENSE' }
  s.author       = { 'crzorz' => 'crzorz@outlook.com' }
  s.source       = { :git => 'https://github.com/BaldStudio/BsLogging.git', :tag => s.version.to_s }

  s.swift_version = '5.0'
  s.static_framework = true

  s.ios.deployment_target = "13.0"
  s.osx.deployment_target = "13.0"

  s.source_files = 'BsLogging/Sources/**/*.swift'
end
