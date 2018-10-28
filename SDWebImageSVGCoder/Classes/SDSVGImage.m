//
//  SDSVGImage.m
//  SDWebImageSVGCoder
//
//  Created by DreamPiggy on 2018/10/10.
//

#import "SDSVGImage.h"
#import "SDWebImageSVGCoderDefine.h"

@interface SDSVGImage ()

@property (nonatomic, strong, nullable) SVGKImage *SVGImage;

@end

@implementation SDSVGImage

- (instancetype)initWithSVGImage:(SVGKImage *)image {
    NSParameterAssert(image);
    UIImage *posterImage = image.UIImage;
#if SD_UIKIT
    UIImageOrientation imageOrientation = posterImage.imageOrientation;
#else
    CGImagePropertyOrientation imageOrientation = kCGImagePropertyOrientationUp;
#endif
    self = [super initWithCGImage:posterImage.CGImage scale:posterImage.scale orientation:imageOrientation];
    if (self) {
        self.SVGImage = image;
    }
    return self;
}

+ (instancetype)imageWithContentsOfFile:(NSString *)path {
    return [[self alloc] initWithContentsOfFile:path];
}

+ (instancetype)imageWithData:(NSData *)data {
    return [[self alloc] initWithData:data];
}

+ (instancetype)imageWithData:(NSData *)data scale:(CGFloat)scale {
    return [[self alloc] initWithData:data scale:scale];
}

- (instancetype)initWithData:(NSData *)data {
    return [self initWithData:data scale:1];
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self initWithData:data];
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    return [self initWithData:data scale:scale options:nil];
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale options:(SDImageCoderOptions *)options {
    SVGKImage *svgImage = [[SVGKImage alloc] initWithData:data];
    if (!svgImage) {
        return nil;
    }
    // Check specified image size
    SDWebImageContext *context = options[SDImageCoderWebImageContext];
    if (context[SDWebImageContextSVGImageSize]) {
        NSValue *sizeValue = context[SDWebImageContextSVGImageSize];
#if SD_UIKIT
        CGSize imageSize = sizeValue.CGSizeValue;
#else
        CGSize imageSize = sizeValue.sizeValue;
#endif
        if (!CGSizeEqualToSize(imageSize, CGSizeZero)) {
            svgImage.size = imageSize;
        }
    }
    return [self initWithSVGImage:svgImage];
}

- (instancetype)initWithAnimatedCoder:(id<SDAnimatedImageCoder>)animatedCoder scale:(CGFloat)scale {
    // Does not support progressive load for SVG images at all
    return nil;
}

#pragma mark - SDAnimatedImageProvider

- (nullable NSData *)animatedImageData {
    return nil;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    return 0;
}

- (nullable UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    return nil;
}

- (NSUInteger)animatedImageFrameCount {
    return 0;
}

- (NSUInteger)animatedImageLoopCount {
    return 0;
}

@end
