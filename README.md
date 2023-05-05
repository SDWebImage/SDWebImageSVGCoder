# SDWebImageSVGCoder

[![CI Status](https://img.shields.io/travis/SDWebImage/SDWebImageSVGCoder.svg?style=flat)](https://travis-ci.org/SDWebImage/SDWebImageSVGCoder)
[![Version](https://img.shields.io/cocoapods/v/SDWebImageSVGCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageSVGCoder)
[![License](https://img.shields.io/cocoapods/l/SDWebImageSVGCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageSVGCoder)
[![Platform](https://img.shields.io/cocoapods/p/SDWebImageSVGCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageSVGCoder)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/SDWebImage/SDWebImageSVGCoder)


## Background

Currently SDWebImage org provide 3 kinds of SVG Coder Plugin support, here is comparison:

| Plugin Name| Vector Image | Bitmap Image | Platform | Compatibility | Dependency |
|---|---|---|---|---|---|
| [SVGNativeCoder](https://github.com/SDWebImage/SDWebImageSVGNativeCoder) | NO | YES | iOS 9+ | Best and W3C standard | adobe/svg-native-viewer |
| [SVGCoder](https://github.com/SDWebImage/SDWebImageSVGCoder) | YES | YES | iOS 13+ | OK but buggy on some SVG | Apple CoreSVG(Private) |
| [SVGKitPlugin](https://github.com/SDWebImage/SDWebImageSVGKitPlugin) | YES | NO | iOS 9+ | Worst, no longer maintain | SVGKit/SVGKit    

## What's for
SDWebImageSVGCoder is a SVG coder plugin for [SDWebImage](https://github.com/rs/SDWebImage/) framework, which provide the image loading support for [SVG](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics).

The SVG rendering is done using Apple's framework CoreSVG.framework (introduced in iOS 13/macOS 10.15).

## Note for SVGKit user

Previously before 1.0.0 version, this SVG Coder is powered by third party library [SVGKit](https://github.com/SVGKit/SVGKit). Which support iOS 8+(macOS 10.10+) as well.

However, due to the lack support of that third party library, which contains massive issues without community's help, no clarity of version release, makes a pain for us to maintain. So, We decide to deprecate SVGKit support and move it into another repo: [SDWebImageSVGKitPlugin](https://github.com/SDWebImage/SDWebImageSVGKitPlugin).

User who use SVGKit or have to support iOS 8+(macOS 10.10+) can still use that SDWebImageSVGKitPlugin instead. You can also mix these two SVG coders at the same time. But since Apple already provide a built-in framework support, we prefer to use that instead, which can reduce complicated dependency, code size, and get polished from Apple's system upgrade.

## Note for CoreSVG framework

So far (Xcode 11.4 && iOS 13.4), the CoreSVG.framework is still in private framework. I've already send the feedback radar to ask for the public for this framework. If you want, please help us to fire radars and request to Apple as well: https://feedbackassistant.apple.com/

The CoreSVG.framework API is stable and match the same concept as CoreGraphics's PDF API, so it's no reason to keep private. And we've already submitted Apps which use the CoreSVG to render the vector images on App Store.

All the SPI access here we use the runtime access and early check, even if future OS upgrade break the function, this framework will not crash your App and just load failed. I'll keep update to the latest changes for each firmware update.

If you still worry about the SPI usage, you can use [SDWebImageSVGKitPlugin](https://github.com/SDWebImage/SDWebImageSVGKitPlugin). But we may not response to any parser or rendering issue related to [SVGKit](https://github.com/SVGKit/SVGKit), because it's already no longer maintained.

There is also another solution: [SVG-Native](https://w3c.github.io/svgwg/specs/svg-native/index.html), a new W3C standard from Adobe, which is a subset of SVG/1.1. Both Apple/Google/Microsoft already join the agreement for this standard, you can try to write your own coder using code from [SVG-native-viewer](https://github.com/adobe/svg-native-viewer/blob/master/svgnative/example/testCocoaCG/SVGNSView.mm) and adopt SVG-native for vector images.

> Warning: Some user report that Apple's CoreSVG has compatible issue for some SVGs (like using non-system Font, gradient), from v1.7.0 we protect some cases, but other exceptions are un-catchable. For these crashes, either use `Render SVG as bitmap image` (see below) or edit your SVG source file to make Apple's CoeSVG compatible.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

You can modify the code or use some other SVG files to check the compatibility.

## Requirements

+ iOS 13+
+ tvOS 13+
+ macOS 10.15+
+ watchOS 6+

## Installation

#### CocoaPods

SDWebImageSVGCoder is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SDWebImageSVGCoder'
```

#### Carthage

SDWebImageSVGCoder is available through [Carthage](https://github.com/Carthage/Carthage).

```
github "SDWebImage/SDWebImageSVGCoder"
```

#### Swift Package Manager

SDWebImageSVGCoder is available through [Swift Package Manager](https://swift.org/package-manager).

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImageSVGCoder.git", from: "1.4")
    ]
)
```

## Usage

### Render SVG as vector image

To use SVG coder, you should firstly add the `SDImageSVGCoder` to the coders manager. Then you can call the View Category method to start load SVG images. See [Wiki - Coder Usage](https://github.com/SDWebImage/SDWebImage/wiki/Advanced-Usage#coder-usage) here for these steps.

Note SVG is a [vector image](https://en.wikipedia.org/wiki/Vector_graphics) format, and UIImageView/NSImageView support rendering vector image as well. Which means you can change the size without losing any details.

+ Objective-C

```objectivec
// register coder, on AppDelegate
SDImageSVGCoder *SVGCoder = [SDImageSVGCoder sharedCoder];
[[SDImageCodersManager sharedManager] addCoder:SVGCoder];
// load SVG url
UIImageView *imageView;
[imageView sd_setImageWithURL:url]
// Changing size
CGRect rect = imageView.frame;
rect.size.width = 200;
rect.size.height = 200;
imageView.frame = rect;
```

+ Swift

```swift
// register coder, on AppDelegate
let SVGCoder = SDImageSVGCoder.shared
SDImageCodersManager.shared.addCoder(SVGCoder)
// load SVG url
let imageView: UIImageView
imageView.sd_setImage(with: url)
// Changing size
var rect = imageView.frame
rect.size.width = 200
rect.size.height = 200
imageView.frame = rect
```

Note since UIImageView/NSImageView support this vector rendering, it means this coder plugin can be compatible for [SwiftUI](https://developer.apple.com/xcode/swiftui/). Check [SDWebImageSwiftUI](https://github.com/SDWebImage/SDWebImageSwiftUI/issues/50) for usage.

Note: for watchOS, which does not support UIKit, so you can not use vector image format. (including both SVG and PDF)

### Render SVG as bitmap image

In most cases, vector SVG is preferred. But however, sometimes you may want the bitmap form of SVG, used for image processing or watchOS.

By default it use the SVG viewBox size. You can also specify a desired size during image loading using `.imageThumbnailPixelSize` context option. And you can specify whether or not to keep aspect ratio during scale using `.imagePreserveAspectRatio` context option.

Note: When using `imageThumbnailPixelSize`, pass 0 for width or height will remove the limit of this length. For example, given a SVG image which original size is `(40,50)`:

| preserve aspect ratio | width | height | effect |
| --- | --- | --- | --- |
| true | 50 | 50 | (40,50) |
| true | 0 | 100 | (80,100) |
| true | 20 | 0 | (20,25) |
| true | 0 | 0 | (40,50) |
| false | 50 | 50 | (50,50) |
| false | 0 | 100 | (40,100) |
| false | 20 | 0 | (20,50) |
| false | 0 | 0 | (40,50) |

Note: Once you pass the `imageThumbnailPixelSize`, we will always generate the bitmap representation. If you do want the vector format, do not pass them, let `UIImageView` to dynamically stretch the SVG.

+ Objective-C

```objectivec
UIImageView *imageView;
CGSize bitmapSize = CGSizeMake(500, 500);
[imageView sd_setImageWithURL:url placeholderImage:nil options:0 context:@{SDWebImageContextThumbnailPixelSize: @(bitmapSize)];
```

+ Swift

```swift
let imageView: UIImageView
let bitmapSize = CGSize(width: 500, height: 500)
imageView.sd_setImage(with: url, placeholderImage: nil, options: [], context: [.imageThumbnailPixelSize : bitmapSize])
```

## Export SVG data

`SDWebImageSVGCoder` provide an easy way to export the SVG image generated by this coder plugin, to the original SVG data.

Note: The bitmap form of SVG does not support SVG data export.

+ Objective-C

```objectivec
UIImage *svgImage; // UIImage with vector image, or NSImage contains `NSSVGImageRep`
if (svgImage.sd_isVector) { // This API available in SDWebImage 5.6.0
    NSData *svgData = [svgImage sd_imageDataAsFormat:SDImageFormatSVG];
}
```

+ Swift

```swift
let svgImage: UIImage // UIImage with vector image, or NSImage contains `NSSVGImageRep`
if svgImage.sd_isVector { // This API available in SDWebImage 5.6.0
    let svgData = svgImage.sd_imageData(as: .SVG)
}
```

## Compatibility for CoreSVG framework

#### The CSS `opacity` can not been applied when `fill` color exists

+ Example

```html
<path d="M399.8,68.2c77.3,3.1,160.6,32.1" opacity="0.15" fill="rgb(29,36,60)" />
```

+ Behavior

App Crash.

+ Workaround: Use CSS `rgba` to set the opacity instead.

```html
<path d="M399.8,68.2c77.3,3.1,160.6,32.1" fill="rgba(29,36,60,0.15)" />
```

## Backward Deployment

This framework supports backward deployment on iOS 12-/macOS 10.14-. And you can combine both `SDWebImageSVGCoder` for higher firmware version, use `SDWebImageSVGKitPlugin` for lower firmware version.

For CocoaPods user, you can skip the platform version validation in Podfile with:

```ruby
platform :ios, '13.0' # This does not effect your App Target's deployment target version, just a hint for CocoaPods
```

Pay attention, you should always use the runtime version check to ensure those symbols are available, you should mark all the classes use public API with `API_AVAILABLE` annotation as well. See below:

```objective-c
if (@available(iOS 13, *)) {
    [SDImageCodersManager.sharedCoder addCoder:SDImageSVGCoder.sharedCoder];
} else {
    [SDImageCodersManager.sharedCoder addCoder:SDImageSVGKCoder.sharedCoder];
}
```

## Screenshot

<img src="https://raw.githubusercontent.com/SDWebImage/SDWebImageSVGCoder/master/Example/Screenshot/SVGDemo.png" width="300" />
<img src="https://raw.githubusercontent.com/SDWebImage/SDWebImageSVGCoder/master/Example/Screenshot/SVGDemo-macOS.png" width="600" />

These SVG images are from [wikimedia](https://commons.wikimedia.org/wiki/Main_Page), you can try the demo with your own SVG image as well.

## Author

DreamPiggy

## License

SDWebImageSVGCoder is available under the MIT license. See the LICENSE file for more info.


