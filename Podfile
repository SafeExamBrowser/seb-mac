# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
# use_frameworks!

#target 'Safe Exam Browser' do
#
#platform :osx, '10.11'
#use_frameworks!
#
#end


target 'SEB' do

platform :ios, '11'
use_frameworks!
pod 'InAppSettingsKit', :git => 'https://github.com/SafeExamBrowser/InAppSettingsKit.git'#, :branch => 'Crash_after_selection'
pod 'JitsiMeetSDK', '~> 3.9.0'#, :git => 'https://github.com/jitsi/jitsi-meet-ios-sdk-releases.git'

end


#target 'SEBVerificator' do
#
#platform :osx, '10.11'
#use_frameworks!
#
#end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
