#
# Be sure to run `pod lib lint PurchaseController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PurchaseController'
  s.version          = '1.0.10'
  s.summary          = 'A helpful and convenient In-App purchases framework'

  s.homepage         = 'http://dashdevs.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'dashdevs llc' => 'hello@dashdevs.com' }
  s.source           = { :git => 'https://github.com/dashdevs/PurchaseController.git', :tag => s.version }

  s.ios.deployment_target = '10.0'

  s.source_files = 'PurchaseController/Classes/**/*', 'PurchaseController/Headers/**/*'

  s.frameworks = 'StoreKit'
  s.dependency 'GRKOpenSSLFramework', '1.0.2.16'
  s.swift_version = '4.2'

end
