# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
# use_frameworks!

target 'Safe Exam Browser' do

platform :osx, '10.11'
pod 'CocoaLumberjack'

end

target 'SEB' do

platform :ios, '11'
pod 'CocoaLumberjack'
pod 'InAppSettingsKit', '~> 2.15'#, :git => 'https://github.com/futuretap/InAppSettingsKit.git'
pod 'QRCodeReaderViewController', '~> 4.0.2'
pod 'JitsiMeetSDK'#, '~> 2.10.2'#, :git => 'https://github.com/jitsi/jitsi-meet-ios-sdk-releases.git'

end

target 'SEB Dev' do

platform :ios, '11'
pod 'CocoaLumberjack'
pod 'InAppSettingsKit', '~> 2.15'#, :git => 'https://github.com/futuretap/InAppSettingsKit.git'
pod 'QRCodeReaderViewController', '~> 4.0.2'
pod 'JitsiMeetSDK'#, '~> 2.10.2'#, :git => 'https://github.com/jitsi/jitsi-meet-ios-sdk-releases.git'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
