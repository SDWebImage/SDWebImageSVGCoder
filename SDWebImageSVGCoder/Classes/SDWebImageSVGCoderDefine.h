//
//  SDWebImageSVGCoderDefine.h
//  SDWebImageSVGCoder
//
//  Created by DreamPiggy on 2018/10/11.
//

@import SDWebImage;

/**
 A CGSize raw value which specify the desired SVG image size during image loading. Because vector image like SVG format, may not contains a fixed size, or you want to get a larger size bitmap representation UIImage. (NSValue)
 If you don't provide this value, use viewBox size of SVG for default value;
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextSVGImageSize;

/**
 A BOOL value which specify the whether SVG image should keep aspect ratio during image loading. Because when you specify image size via `SDWebImageContextSVGImageSize`, we need to know whether to keep aspect ratio or not when image size aspect ratio is not equal to SVG viewBox size aspect ratio. (NSNumber)
 If you don't provide this value, use YES for default value.
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextSVGImagePreserveAspectRatio;
