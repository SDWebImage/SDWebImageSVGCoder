//
//  SDImageSVGCoder.m
//  SDWebImageSVGCoder
//
//  Created by DreamPiggy on 2018/9/27.
//

#import "SDImageSVGCoder.h"
#import "SDSVGImage.h"
#import "SDWebImageSVGCoderDefine.h"
#import <SVGKit/SVGKit.h>
#import <dlfcn.h>

#define kSVGTagEnd @"</svg>"

typedef struct CF_BRIDGED_TYPE(id) CGSVGDocument *CGSVGDocumentRef;
static CGSVGDocumentRef (*CGSVGDocumentCreateFromDataProvider)(CGDataProviderRef provider, CFDictionaryRef options);
static CGSVGDocumentRef (*CGSVGDocumentRetain)(CGSVGDocumentRef);
static void (*CGSVGDocumentRelease)(CGSVGDocumentRef);

#if SD_UIKIT

@interface UIImage (PrivateSVGSupport)

- (instancetype)_initWithCGSVGDocument:(CGSVGDocumentRef)document;
- (instancetype)_initWithCGSVGDocument:(CGSVGDocumentRef)document scale:(double)scale orientation:(UIImageOrientation)orientation;
+ (instancetype)_imageWithCGSVGDocument:(CGSVGDocumentRef)document;
+ (instancetype)_imageWithCGSVGDocument:(CGSVGDocumentRef)document scale:(double)scale orientation:(UIImageOrientation)orientation;
- (CGSVGDocumentRef)_CGSVGDocument;

@end

#endif

@implementation SDImageSVGCoder

+ (SDImageSVGCoder *)sharedCoder {
    static dispatch_once_t onceToken;
    static SDImageSVGCoder *coder;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageSVGCoder alloc] init];
    });
    return coder;
}

+ (void)initialize {
    CGSVGDocumentCreateFromDataProvider = dlsym(RTLD_DEFAULT, "CGSVGDocumentCreateFromDataProvider");
    CGSVGDocumentRetain = dlsym(RTLD_DEFAULT, "CGSVGDocumentRetain");
    CGSVGDocumentRelease = dlsym(RTLD_DEFAULT, "CGSVGDocumentRelease");
}

#pragma mark - Decode

- (BOOL)canDecodeFromData:(NSData *)data {
    return [self.class isSVGFormatForData:data];
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
#if SD_UIKIT
    if ([self.class supportsVectorSVGImage]) {
        return [self createVectorSVGWithData:data options:options];
    } else {
        return [self createBitmapSVGWithData:data options:options];
    }
#else
    return [self createBitmapSVGWithData:data options:options];
#endif
}

#if SD_UIKIT
- (UIImage *)createVectorSVGWithData:(NSData *)data options:(SDImageCoderOptions *)options {
    NSParameterAssert(data);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    if (!provider) {
        return nil;
    };
    CGSVGDocumentRef document = CGSVGDocumentCreateFromDataProvider(provider, NULL);
    if (!document) {
        return nil;
    }
    UIImage *image = [UIImage _imageWithCGSVGDocument:document];
    CGSVGDocumentRelease(document);

    return image;
}
#endif

- (UIImage *)createBitmapSVGWithData:(NSData *)data options:(SDImageCoderOptions *)options {
    NSParameterAssert(data);
    // Parse SVG
    SVGKImage *svgImage = [[SVGKImage alloc] initWithData:data];
    if (!svgImage) {
        return nil;
    }
    
    CGSize imageSize = CGSizeZero;
    BOOL preserveAspectRatio = YES;
    // Parse args
    SDWebImageContext *context = options[SDImageCoderWebImageContext];
    if (context[SDWebImageContextSVGImageSize]) {
        NSValue *sizeValue = context[SDWebImageContextSVGImageSize];
#if SD_UIKIT
        imageSize = sizeValue.CGSizeValue;
#else
        imageSize = sizeValue.sizeValue;
#endif
    }
    if (context[SDWebImageContextSVGImagePreserveAspectRatio]) {
        preserveAspectRatio = [context[SDWebImageContextSVGImagePreserveAspectRatio] boolValue];
    }
    
    if (!CGSizeEqualToSize(imageSize, CGSizeZero)) {
        if (preserveAspectRatio) {
            [svgImage scaleToFitInside:imageSize];
        } else {
            svgImage.size = imageSize;
        }
    }
    
    UIImage *image = svgImage.UIImage;
    if (!image) {
        return nil;
    }
    
    // SVG is vector image, so no need scale factor
    image.sd_imageFormat = SDImageFormatSVG;
    
    return image;
}

#pragma mark - Encode

- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return format == SDImageFormatSVG;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(SDImageCoderOptions *)options {
    // Only support SVGKImage wrapper
    if (![image isKindOfClass:SDSVGImage.class]) {
        return nil;
    }
    SVGKImage *svgImage = ((SDSVGImage *)image).SVGImage;
    if (!svgImage) {
        return nil;
    }
    SVGKSource *source = svgImage.source;
    // Should be NSData type source
    if (![source isKindOfClass:SVGKSourceNSData.class]) {
        return nil;
    }
    return ((SVGKSourceNSData *)source).rawData;
}

#pragma mark - Helper

+ (BOOL)supportsVectorSVGImage {
#if SD_MAC
    return NO;
#else
    static dispatch_once_t onceToken;
    static BOOL supports;
    dispatch_once(&onceToken, ^{
        // iOS 11+ supports PDF built-in rendering, use selector to check is more accurate
        if ([UIImage respondsToSelector:@selector(_imageWithCGSVGDocument:)]) {
            supports = YES;
        } else {
            supports = NO;
        }
    });
    return supports;
#endif
}

+ (BOOL)isSVGFormatForData:(NSData *)data {
    if (!data) {
        return NO;
    }
    if (data.length <= 100) {
        return NO;
    }
    // Check end with SVG tag
    NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(data.length - 100, 100)] encoding:NSASCIIStringEncoding];
    if (![testString containsString:kSVGTagEnd]) {
        return NO;
    }
    return YES;
}

@end
