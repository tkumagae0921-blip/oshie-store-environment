Pod::Spec.new do |s|
  s.name = 'oshie_store_environment'
  s.version = '0.2.0'
  s.summary = 'Oshie read-only iOS environment routing hint.'
  s.description = 'No purchase, restore, receipt contents, network or grant operations.'
  s.homepage = 'https://tipies.jp'
  s.license = { :type => 'Proprietary', :file => '../LICENSE' }
  s.author = { 'Tipies' => 'https://tipies.jp' }
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'
end
