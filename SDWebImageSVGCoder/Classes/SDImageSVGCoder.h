//
//  SDImageSVGCoder.h
//  SDWebImageSVGCoder
//
//  Created by DreamPiggy on 2018/9/27.
//

#import <SDWebImage/SDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

static const SDImageFormat SDImageFormatSVG = 12;

@interface SDImageSVGCoder : NSObject <SDImageCoder>

@property (nonatomic, class, readonly) SDImageSVGCoder *sharedCoder;

@end

NS_ASSUME_NONNULL_END
