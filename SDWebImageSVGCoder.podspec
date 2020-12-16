#
# Be sure to run `pod lib lint SDWebImageSVGCoder.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SDWebImageSVGCoder'
  s.version          = '1.6.0'
  s.summary          = 'A SVG coder plugin for SDWebImage, using Apple built-in framework'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/SDWebImage/SDWebImageSVGCoder'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lizhuoli1126@126.com' => 'lizhuoli1126@126.com' }
  s.source           = { :git => 'https://github.com/SDWebImage/SDWebImageSVGCoder.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.watchos.deployment_target = '6.0'

  s.source_files = 'SDWebImageSVGCoder/Classes/**/*', 'SDWebImageSVGCoder/Module/SDWebImageSVGCoder.h'
  s.module_map = 'SDWebImageSVGCoder/Module/SDWebImageSVGCoder.modulemap'

  s.pod_target_xcconfig = {
    'SUPPORTS_MACCATALYST' => 'YES',
    'DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER' => 'NO'
  }
  
  s.dependency 'SDWebImage/Core', '~> 5.6'
end
