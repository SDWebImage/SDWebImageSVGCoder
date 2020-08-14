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
    SDCGSVGDocumentRetain = dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dTVkdEb2N1bWVudFJldGFpbg==").UTF8String);
    SDCGSVGDocumentRelease = dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dTVkdEb2N1bWVudFJlbGVhc2U=").UTF8String);
    SDCGSVGDocumentCreateFromData = dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dTVkdEb2N1bWVudENyZWF0ZUZyb21EYXRh").UTF8String);
    SDCGSVGDocumentWriteToData = dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dTVkdEb2N1bWVudFdyaXRlVG9EYXRh").UTF8String);
    SDCGContextDrawSVGDocument = dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dDb250ZXh0RHJhd1NWR0RvY3VtZW50").UTF8String);
    SDCGSVGDocumentGetCanvasSize = dlsym(RTLD_DEFAULT, SDBase64DecodedString(@"Q0dTVkdEb2N1bWVudEdldENhbnZhc1NpemU=").UTF8String);
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
        preserveAspectRatio = [context[SDImageCoderDecodePreserveAspectRatio] boolValue];
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
    
    SDCGSVGDocumentWriteToData(document, (__bridge CFDataRef)data, NULL);
    
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
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGRect targetRect = rect;
    if (!CGSizeEqualToSize(targetSize, CGSizeZero)) {
        targetRect = CGRectMake(0, 0, targetSize.width, targetSize.height);
    }
    
    CGFloat xRatio = targetRect.size.width / rect.size.width;
    CGFloat yRatio = targetRect.size.height / rect.size.height;
    CGFloat xScale = preserveAspectRatio ? MIN(xRatio, yRatio) : xRatio;
    CGFloat yScale = preserveAspectRatio ? MIN(xRatio, yRatio) : yRatio;
    
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
