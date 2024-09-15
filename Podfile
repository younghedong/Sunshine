platform :tvos, '16.0'

target 'Sunshine' do
  use_frameworks!

  pod 'TVVLCKit'
  pod 'AMSMB2'

  # 其他目标...
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['TVOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['EXCLUDED_ARCHS'] = ''
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end
