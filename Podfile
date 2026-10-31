platform :ios, '15.0'

def sharedPods
 pod "Realm"
 pod "Facade"
 pod "SDWebImage", "~>3.7"
end

target 'xkcd Open Source' do
 sharedPods
 pod "FLAnimatedImage", "~> 1.0"
end

target 'xkcdToday' do
 sharedPods
end

target 'xkcdOSTests' do
 sharedPods
 pod "FLAnimatedImage", "~> 1.0"
 pod "OHHTTPStubs"
end

# Several pods declare very old minimum iOS versions, which current Xcode rejects, so build them
# all against our deployment target.
post_install do |installer|
 installer.pods_project.targets.each do |target|
  target.build_configurations.each do |config|
   config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  end
 end
end
