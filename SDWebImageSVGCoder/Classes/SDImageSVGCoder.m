//
//  SDImageSVGCoder.m
//  SDWebImageSVGCoder
//
//  Created by DreamPiggy on 2018/9/27.
//

#import "SDImageSVGCoder.h"
#import "SDWebImageSVGCoderDefine.h"
#import <dlfcn.h>
#import <objc/runtime.h>

#define kSVGTagEnd @"</svg>"

typedef struct CF_BRIDGED_TYPE(id) CGSVGDocument *CGSVGDocumentRef;
static CGSVGDocumentRef (*SDCGSVGDocumentRetain)(CGSVGDocumentRef);
static void (*SDCGSVGDocumentRelease)(CGSVGDocumentRef);
static CGSVGDocumentRef (*SDCGSVGDocumentCreateFromData)(CFDataRef data, CFDictionaryRef options);
static void (*SDCGSVGDocumentWriteToData)(CGSVGDocumentRef document, CFDataRef data, CFDictionaryRef options);
static void (*SDCGContextDrawSVGDocument)(CGContextRef context, CGSVGDocumentRef document);
static CGSize (*SDCGSVGDocumentGetCanvasSize)(CGSVGDocumentRef document);

#if SD_UIKIT || SD_WATCH
static SEL SDImageWithCGSVGDocumentSEL = NULL;
static SEL SDCGSVGDocumentSEL = NULL;
#endif
#if SD_MAC
static Class SDNSSVGImageRepClass = NULL;
static Ivar SDNSSVGImageRepDocumentIvar = NULL;
#endif

static inline NSString *SDBase64DecodedString(NSString *base64String) {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

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
    SDCGSVGDocumentRetain = (CGSVGDocumentRef (*)(CGSVGDocumentRef))dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dTVkdEb2N1bWVudFJldGFpbg==").UTF8String);
    SDCGSVGDocumentRelease = (void (*)(CGSVGDocumentRef))dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dTVkdEb2N1bWVudFJlbGVhc2U=").UTF8String);
    SDCGSVGDocumentCreateFromData = (CGSVGDocumentRef (*)(CFDataRef data, CFDictionaryRef options))dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dTVkdEb2N1bWVudENyZWF0ZUZyb21EYXRh").UTF8String);
    SDCGSVGDocumentWriteToData = (void (*)(CGSVGDocumentRef document, CFDataRef data, CFDictionaryRef options))dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dTVkdEb2N1bWVudFdyaXRlVG9EYXRh").UTF8String);
    SDCGContextDrawSVGDocument = (void (*)(CGContextRef context, CGSVGDocumentRef document))dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dDb250ZXh0RHJhd1NWR0RvY3VtZW50").UTF8String);
    SDCGSVGDocumentGetCanvasSize = (CGSize (*)(CGSVGDocumentRef document))dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dTVkdEb2N1bWVudEdldENhbnZhc1NpemU=").UTF8String);
#if SD_UIKIT || SD_WATCH
    SDImageWithCGSVGDocumentSEL = NSSelectorFromString(SDBase64DecodedString(@"X2ltYWdlV2l0aENHU1ZHRG9jdW1lbnQ6"));
    SDCGSVGDocumentSEL = NSSelectorFromString(SDBase64DecodedString(@"X0NHU1ZHRG9jdW1lbnQ="));
#endif
#if SD_MAC
    SDNSSVGImageRepClass = NSClassFromString(SDBase64DecodedString(@"X05TU1ZHSW1hZ2VSZXA="));
    if (SDNSSVGImageRepClass) {
        SDNSSVGImageRepDocumentIvar = class_getInstanceVariable(SDNSSVGImageRepClass, SDBase64DecodedString(@"X2RvY3VtZW50").UTF8String);
    }
#endif
}

#pragma mark - Decode

- (BOOL)canDecodeFromData:(NSData *)data {
    return [self.class isSVGFormatForData:data];
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    
    BOOL prefersBitmap = NO;
    CGSize imageSize = CGSizeZero;
    BOOL preserveAspectRatio = YES;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // Parse args
    SDWebImageContext *context = options[SDImageCoderWebImageContext];
    if (context[SDWebImageContextSVGImageSize]) {
        prefersBitmap = YES;
        NSValue *sizeValue = context[SDWebImageContextSVGImageSize];
#if SD_MAC
        imageSize = sizeValue.sizeValue;
#else
        imageSize = sizeValue.CGSizeValue;
#endif
    } else if (options[SDImageCoderDecodeThumbnailPixelSize]) {
        prefersBitmap = YES;
        NSValue *sizeValue = options[SDImageCoderDecodeThumbnailPixelSize];
#if SD_MAC
        imageSize = sizeValue.sizeValue;
#else
        imageSize = sizeValue.CGSizeValue;
#endif
    } else if (context[SDWebImageContextSVGPrefersBitmap]) {
        prefersBitmap = [context[SDWebImageContextSVGPrefersBitmap] boolValue];
    }
    if (context[SDWebImageContextSVGImagePreserveAspectRatio]) {
        preserveAspectRatio = [context[SDWebImageContextSVGImagePreserveAspectRatio] boolValue];
    } else if (options[SDImageCoderDecodePreserveAspectRatio]) {
        preserveAspectRatio = [options[SDImageCoderDecodePreserveAspectRatio] boolValue];
    }
#pragma clang diagnostic pop
    
    UIImage *image;
    if (!prefersBitmap && [self.class supportsVectorSVGImage]) {
        image = [self createVectorSVGWithData:data];
    } else {
        image = [self createBitmapSVGWithData:data targetSize:imageSize preserveAspectRatio:preserveAspectRatio];
    }
    
    image.sd_imageFormat = SDImageFormatSVG;
    
    return image;
}

#pragma mark - Encode

- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return format == SDImageFormatSVG;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(SDImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    if (![self.class supportsVectorSVGImage]) {
        return nil;
    }
    NSMutableData *data = [NSMutableData data];
    CGSVGDocumentRef document = NULL;
#if SD_MAC
    NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
    NSImageRep *imageRep = [image bestRepresentationForRect:imageRect context:nil hints:nil];
    if ([imageRep isKindOfClass:SDNSSVGImageRepClass]) {
        document = (__bridge CGSVGDocumentRef)(object_getIvar(imageRep, SDNSSVGImageRepDocumentIvar));
    }
#else
    document = ((CGSVGDocumentRef (*)(id,SEL))[image methodForSelector:SDCGSVGDocumentSEL])(image, SDCGSVGDocumentSEL);
#endif
    if (!document) {
        return nil;
    }
    
    @try {
        // WARNING! Some CoreSVG exceptions can be catched, but not always
        // If you finally crash here (un-catchable), you can only workaround (or hope Apple fix this)
        // Do not encode vector UIImage into NSData, query `SDImageCache` for the same key and get back SVG Data
        SDCGSVGDocumentWriteToData(document, (__bridge CFMutableDataRef)data, NULL);
    } @catch (...) {
        // CoreSVG export failed
        return nil;
    }
    
    return [data copy];
}

#pragma mark - Vector SVG representation
- (UIImage *)createVectorSVGWithData:(nonnull NSData *)data {
    NSParameterAssert(data);
    UIImage *image;
    
#if SD_MAC
    Class imageRepClass = SDNSSVGImageRepClass;
    NSImageRep *imageRep = [[imageRepClass alloc] initWithData:data];
    if (!imageRep) {
        return nil;
    }
    image = [[NSImage alloc] initWithSize:imageRep.size];
    [image addRepresentation:imageRep];
#else
    CGSVGDocumentRef document = SDCGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
    if (!document) {
        return nil;
    }
    image = ((UIImage *(*)(id,SEL,CGSVGDocumentRef))[UIImage.class methodForSelector:SDImageWithCGSVGDocumentSEL])(UIImage.class, SDImageWithCGSVGDocumentSEL, document);
    SDCGSVGDocumentRelease(document);
#endif
    
    // CoreSVG has compatible for some SVG/1.1 format (like Font issue) and may crash when rendering on screen (not here, Core Animation commit time)
    // So, we snapshot a 1x1 pixel image and try catch here to check :(
    
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1, 1)];
    @try {
        __unused UIImage *dummyImage = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
            // WARNING! Some CoreSVG exceptions can be catched, but not always
            // If you finally crash here (un-catchable), you can only workaround (or hope Apple fix this)
            // Change your code to use `SDWebImageContextImageThumbnailPixelSize` context option with enough size to render bitmap SVG instead
            [image drawInRect:CGRectMake(0, 0, 1, 1)];
        }];
    } @catch (...) {
        // CoreSVG decode failed
        return nil;
    }
    
    return image;
}

#pragma mark - Bitmap SVG representation
- (UIImage *)createBitmapSVGWithData:(nonnull NSData *)data targetSize:(CGSize)targetSize preserveAspectRatio:(BOOL)preserveAspectRatio {
    NSParameterAssert(data);
    UIImage *image;
    
    CGSVGDocumentRef document = SDCGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
    if (!document) {
        return nil;
    }
    
    CGSize size = SDCGSVGDocumentGetCanvasSize(document);
    // Invalid size
    if (size.width == 0 || size.height == 0) {
        return nil;
    }
    
    CGFloat xScale;
    CGFloat yScale;
    // Calculation for actual target size, see rules in documentation
    if (targetSize.width <= 0 && targetSize.height <= 0) {
        // Both width and height is 0, use original size
        targetSize.width = size.width;
        targetSize.height = size.height;
        xScale = 1;
        yScale = 1;
    } else {
        CGFloat xRatio = targetSize.width / size.width;
        CGFloat yRatio = targetSize.height / size.height;
        if (preserveAspectRatio) {
            // If we specify only one length of the size (width or height) we want to keep the ratio for that length
            if (targetSize.width <= 0) {
                yScale = yRatio;
                xScale = yRatio;
                targetSize.width = size.width * xScale;
            } else if (targetSize.height <= 0) {
                xScale = xRatio;
                yScale = xRatio;
                targetSize.height = size.height * yScale;
            } else {
                xScale = MIN(xRatio, yRatio);
                yScale = MIN(xRatio, yRatio);
                targetSize.width = size.width * xScale;
                targetSize.height = size.height * yScale;
            }
        } else {
            // If we specify only one length of the size but don't keep the ratio, use original size
            if (targetSize.width <= 0) {
                targetSize.width = size.width;
                yScale = yRatio;
                xScale = 1;
            } else if (targetSize.height <= 0) {
                xScale = xRatio;
                yScale = 1;
                targetSize.height = size.height;
            } else {
                xScale = xRatio;
                yScale = yRatio;
            }
        }
    }
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGRect targetRect = CGRectMake(0, 0, targetSize.width, targetSize.height);
    
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(xScale, yScale);
    CGAffineTransform transform = CGAffineTransformIdentity;
    if (preserveAspectRatio) {
        // Calculate the offset
        transform = CGAffineTransformMakeTranslation((targetRect.size.width / xScale - rect.size.width) / 2, (targetRect.size.height / yScale - rect.size.height) / 2);
    }
    
    SDGraphicsBeginImageContextWithOptions(targetRect.size, NO, 0);
    CGContextRef context = SDGraphicsGetCurrentContext();
    
#if SD_UIKIT || SD_WATCH
    // Core Graphics coordinate system use the bottom-left, UIkit use the flipped one
    CGContextTranslateCTM(context, 0, targetRect.size.height);
    CGContextScaleCTM(context, 1, -1);
#endif
    
    CGContextConcatCTM(context, scaleTransform);
    CGContextConcatCTM(context, transform);
    
    SDCGContextDrawSVGDocument(context, document);
    
    image = SDGraphicsGetImageFromCurrentImageContext();
    SDGraphicsEndImageContext();
    
    SDCGSVGDocumentRelease(document);
    
    return image;
}

#pragma mark - Helper

+ (BOOL)supportsVectorSVGImage {
    static dispatch_once_t onceToken;
    static BOOL supports;
    dispatch_once(&onceToken, ^{
#if SD_MAC
        // macOS 10.15+ supports SVG built-in rendering, use selector to check is more accurate
        if (SDNSSVGImageRepClass) {
            supports = YES;
        } else {
            supports = NO;
        }
#else
        // iOS 13+ supports SVG built-in rendering, use selector to check is more accurate
        if ([UIImage respondsToSelector:SDImageWithCGSVGDocumentSEL]) {
            supports = YES;
        } else {
            supports = NO;
        }
#endif
    });
    return supports;
}

+ (BOOL)isSVGFormatForData:(NSData *)data {
    if (!data) {
        return NO;
    }
    // Check end with SVG tag
    return [data rangeOfData:[kSVGTagEnd dataUsingEncoding:NSUTF8StringEncoding] options:NSDataSearchBackwards range: NSMakeRange(data.length - MIN(100, data.length), MIN(100, data.length))].location != NSNotFound;
}

@end
