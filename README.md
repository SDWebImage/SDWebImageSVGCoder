# SDWebImageSVGCoder

[![CI Status](https://img.shields.io/travis/SDWebImage/SDWebImageSVGCoder.svg?style=flat)](https://travis-ci.org/SDWebImage/SDWebImageSVGCoder)
[![Version](https://img.shields.io/cocoapods/v/SDWebImageSVGCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageSVGCoder)
[![License](https://img.shields.io/cocoapods/l/SDWebImageSVGCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageSVGCoder)
[![Platform](https://img.shields.io/cocoapods/p/SDWebImageSVGCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageSVGCoder)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/SDWebImage/SDWebImageSVGCoder)


## What's for
SDWebImageSVGCoder is a SVG coder plugin for [SDWebImage](https://github.com/rs/SDWebImage/) framework, which provide the image loading support for [SVG](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics).

The SVG rendering is done using Apple's framework CoreSVG.framework (introduced in iOS 13/macOS 10.15).

## Note for SVGKit user

Previously before 1.0.0 version, this SVG Coder is powered by third party library [SVGKit](https://github.com/SVGKit/SVGKit). Which support iOS 8+(macOS 10.10+) as well.

However, due to the lack support of that third party library, which contains massive issues without community's help, no clarity of version release, makes a pain for us to maintain. So, We decide to deprecate SVGKit support and move it into another repo: [SDWebImageSVGKitPlugin](https://github.com/SDWebImage/SDWebImageSVGKitPlugin).

User who use SVGKit or have to support iOS 8+(macOS 10.10+) can still use that SDWebImageSVGKitPlugin instead. You can also mix these two SVG coders at the same time. But since Apple already provide a built-in framework support, we prefer to use that instead, which can reduce complicated dependency, code size, and get polished from Apple's system upgrade.

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
        .package(url: "https://github.com/SDWebImage/SDWebImageSVGCoder.git", from: "1.0")
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

### Render SVG as bitmap image

In most cases, vector SVG is preferred. But however, sometimes you may want the bitmap form of SVG, used for image processing. You can use `.svgPrefersBitmap` to provide the bitmap format as well.

By default it use the SVG canvas size. You can also specify a desired size during image loading using `.svgImageSize` context option. And you can specify whether or not to keep aspect ratio during scale using `.svgImagePreserveAspectRatio` context option.

+ Objective-C

```objectivec
UIImageView *imageView;
CGSize SVGImageSize = CGSizeMake(500, 500);
[imageView sd_setImageWithURL:url placeholderImage:nil options:0 context:@{SDWebImageContextSVGPrefersBitmap: @YES, SDWebImageContextSVGImageSize: @(SVGImageSize)];
```

+ Swift

```swift
let imageView: UIImageView
let SVGImageSize = CGSize(width: 500, height: 500)
imageView.sd_setImage(with: url, placeholderImage: nil, options: [], context: [.svgPrefersBitmap : true, .svgImageSize : SVGImageSize])
```

## Export SVG data

`SDWebImageSVGCoder` provide an easy way to export the SVG image generated by this coder plugin, to the original SVG data.

Note: The bitmap form of SVG does not support SVG data export.

+ Objective-C

```objectivec
UIImage *image = imageView.image; // Image generated by this coder plugin
NSData *imageData = [image sd_imageDataAsFormat:SDImageFormatSVG];
```

+ Swift

```swift
let image = imageView.image // Image generated by this coder plugin 
let imageData = image.sd_imageData(as: .SVG)
```

## Screenshot

<img src="https://raw.githubusercontent.com/SDWebImage/SDWebImageSVGCoder/master/Example/Screenshot/SVGDemo.png" width="300" />
<img src="https://raw.githubusercontent.com/SDWebImage/SDWebImageSVGCoder/master/Example/Screenshot/SVGDemo-macOS.png" width="600" />

These SVG images are from [wikimedia](https://commons.wikimedia.org/wiki/Main_Page), you can try the demo with your own SVG image as well.

## Author

DreamPiggy

## License

SDWebImageSVGCoder is available under the MIT license. See the LICENSE file for more info.


