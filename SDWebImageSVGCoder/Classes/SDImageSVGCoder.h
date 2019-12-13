//
//  SDImageSVGCoder.h
//  SDWebImageSVGCoder
//
//  Created by DreamPiggy on 2018/9/27.
//

#if __has_include(<SDWebImage/SDWebImage.h>)
#import <SDWebImage/SDWebImage.h>
#else
@import SDWebImage;
#endif

NS_ASSUME_NONNULL_BEGIN

static const SDImageFormat SDImageFormatSVG = 12;

@interface SDImageSVGCoder : NSObject <SDImageCoder>

@property (nonatomic, class, readonly) SDImageSVGCoder *sharedCoder;

@end

NS_ASSUME_NONNULL_END
