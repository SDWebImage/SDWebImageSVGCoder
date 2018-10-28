//
//  SDWebImageSVGCoderDefine.h
//  SDWebImageSVGCoder
//
//  Created by DreamPiggy on 2018/10/11.
//

#import <SDWebImage/SDWebImage.h>

@class SVGKImage;

#if SD_UIKIT
/**
 Adjust `SVGKImage`'s viewPort && viewBox to match the specify `contentMode` of view size.
 @note Though this util method can be used outside this framework. For simple SVG image loading, it's recommaned to use `sd_adjustContentMode` property on `SVGKImageView+WebCache`.

 @param svgImage `SVGKImage` instance, should not be nil.
 @param contentMode The contentMode to be applied. All possible contentMode are supported.
 @param viewSize Target view size, typically specify the `view.bounds.size`.
 */
FOUNDATION_EXPORT void SDAdjustSVGContentMode(SVGKImage * __nonnull svgImage, UIViewContentMode contentMode, CGSize viewSize);
#endif

/**
 A CGSize raw value which specify the desired SVG image size during image loading. Because vector image like SVG format, may not contains a fixed size, or you want to get a larger size bitmap representation UIImage. (NSValue)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextSVGImageSize;
