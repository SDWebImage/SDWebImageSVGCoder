#
# Be sure to run `pod lib lint SDWebImageSVGCoder.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SDWebImageSVGCoder'
  s.version          = '0.1.0'
  s.summary          = 'A short description of SDWebImageSVGCoder.'

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

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'SDWebImageSVGCoder/Classes/**/*', 'SDWebImageSVGCoder/Module/SDWebImageSVGCoder.h'
  s.module_map = 'SDWebImageSVGCoder/Module/SDWebImageSVGCoder.modulemap'
  
  s.dependency 'SDWebImage/Core', '>= 5.0.0-beta2'
  s.dependency 'SVGKit', '>= 2.x'
end
