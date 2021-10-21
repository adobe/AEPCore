# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPCore'

pod 'SwiftLint', '0.44.0'

target 'AEPCore' do
  project 'AEPCore.xcodeproj'
  pod 'AEPRulesEngine'
end

target 'AEPCoreTests' do
  project 'AEPCore.xcodeproj'
  pod 'AEPRulesEngine'
end

target 'AEPSignalTests' do
  project 'AEPCore.xcodeproj'
  pod 'AEPRulesEngine'
end

target 'AEPLifecycleTests' do
  project 'AEPCore.xcodeproj'
  pod 'AEPRulesEngine'
end

target 'AEPIdentityTests' do
  project 'AEPCore.xcodeproj'
  pod 'AEPRulesEngine'
end

target 'AEPIntegrationTests' do
  project 'AEPCore.xcodeproj'
  pod 'AEPRulesEngine'
end


# TestApps project dependencies

target 'TestApp_Swift' do
  project 'TestApps/AEPCoreTestApp.xcodeproj'
  pod 'AEPRulesEngine'
end

target 'TestApp_Objc' do
  project 'TestApps/AEPCoreTestApp.xcodeproj'
  pod 'AEPRulesEngine'
end

target 'E2E_Swift' do
  project 'TestApps/AEPCoreTestApp.xcodeproj'
  pod 'AEPRulesEngine'
end

target 'PerformanceApp' do
  project 'TestApps/AEPCoreTestApp.xcodeproj'
  pod 'AEPRulesEngine'
end
