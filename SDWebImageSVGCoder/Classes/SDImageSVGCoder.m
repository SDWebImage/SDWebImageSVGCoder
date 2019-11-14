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
static CGSVGDocumentRef (*CGSVGDocumentRetain)(CGSVGDocumentRef);
static void (*CGSVGDocumentRelease)(CGSVGDocumentRef);
static CGSVGDocumentRef (*CGSVGDocumentCreateFromData)(CFDataRef data, CFDictionaryRef options);
static void (*CGSVGDocumentWriteToData)(CGSVGDocumentRef document, CFDataRef data, CFDictionaryRef options);
static void (*CGContextDrawSVGDocument)(CGContextRef context, CGSVGDocumentRef document);
static CGSize (*CGSVGDocumentGetCanvasSize)(CGSVGDocumentRef document);

#if SD_UIKIT || SD_WATCH

@interface UIImage (PrivateSVGSupport)

- (instancetype)_initWithCGSVGDocument:(CGSVGDocumentRef)document;
- (instancetype)_initWithCGSVGDocument:(CGSVGDocumentRef)document scale:(double)scale orientation:(UIImageOrientation)orientation;
+ (instancetype)_imageWithCGSVGDocument:(CGSVGDocumentRef)document;
+ (instancetype)_imageWithCGSVGDocument:(CGSVGDocumentRef)document scale:(double)scale orientation:(UIImageOrientation)orientation;
- (CGSVGDocumentRef)_CGSVGDocument;

@end

#endif

#if SD_MAC

#define NSSVGImageRepClass @"_NSSVGImageRep"
#define NSSVGImageRepDocumentIvar "_document"

@protocol NSSVGImageRepProtocol <NSObject>

- (instancetype)initWithSVGDocument:(CGSVGDocumentRef)document;
- (instancetype)initWithData:(NSData *)data;

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
    CGSVGDocumentRetain = dlsym(RTLD_DEFAULT, "CGSVGDocumentRetain");
    CGSVGDocumentRelease = dlsym(RTLD_DEFAULT, "CGSVGDocumentRelease");
    CGSVGDocumentCreateFromData = dlsym(RTLD_DEFAULT, "CGSVGDocumentCreateFromData");
    CGSVGDocumentWriteToData = dlsym(RTLD_DEFAULT, "CGSVGDocumentWriteToData");
    CGContextDrawSVGDocument = dlsym(RTLD_DEFAULT, "CGContextDrawSVGDocument");
    CGSVGDocumentGetCanvasSize = dlsym(RTLD_DEFAULT, "CGSVGDocumentGetCanvasSize");
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
    // Parse args
    SDWebImageContext *context = options[SDImageCoderWebImageContext];
    if (context[SDWebImageContextSVGPrefersBitmap]) {
        prefersBitmap = [context[SDWebImageContextSVGPrefersBitmap] boolValue];
    }
    if (context[SDWebImageContextSVGImageSize]) {
        NSValue *sizeValue = context[SDWebImageContextSVGImageSize];
#if SD_MAC
        imageSize = sizeValue.sizeValue;
#else
        imageSize = sizeValue.CGSizeValue;
#endif
    }
    if (context[SDWebImageContextSVGImagePreserveAspectRatio]) {
        preserveAspectRatio = [context[SDWebImageContextSVGImagePreserveAspectRatio] boolValue];
    }
    
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
    if ([imageRep isKindOfClass:NSClassFromString(NSSVGImageRepClass)]) {
        Ivar ivar = class_getInstanceVariable(imageRep.class, NSSVGImageRepDocumentIvar);
        document = (__bridge CGSVGDocumentRef)(object_getIvar(imageRep, ivar));
    }
#else
    document = [image _CGSVGDocument];
#endif
    if (!document) {
        return nil;
    }
    
    CGSVGDocumentWriteToData(document, (__bridge CFDataRef)data, NULL);
    
    return [data copy];
}

#pragma mark - Vector SVG representation
- (UIImage *)createVectorSVGWithData:(nonnull NSData *)data {
    NSParameterAssert(data);
    UIImage *image;
    
#if SD_MAC
    Class imageRepClass = NSClassFromString(NSSVGImageRepClass);
    NSImageRep *imageRep = [[imageRepClass alloc] initWithData:data];
    if (!imageRep) {
        return nil;
    }
    image = [[NSImage alloc] initWithSize:imageRep.size];
    [image addRepresentation:imageRep];
#else
    CGSVGDocumentRef document = CGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
    if (!document) {
        return nil;
    }
    image = [UIImage _imageWithCGSVGDocument:document];
    CGSVGDocumentRelease(document);
#endif
    return image;
}

#pragma mark - Bitmap SVG representation
- (UIImage *)createBitmapSVGWithData:(nonnull NSData *)data targetSize:(CGSize)targetSize preserveAspectRatio:(BOOL)preserveAspectRatio {
    NSParameterAssert(data);
    UIImage *image;
    
    CGSVGDocumentRef document = CGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
    if (!document) {
        return nil;
    }
    
    CGSize size = CGSVGDocumentGetCanvasSize(document);
    if (CGSizeEqualToSize(targetSize, CGSizeZero)) {
        targetSize = size;
    }
    
    CGFloat xRatio = targetSize.width / size.width;
    CGFloat yRatio = targetSize.height / size.height;
    CGFloat xScale = preserveAspectRatio ? MIN(xRatio, yRatio) : xRatio;
    CGFloat yScale = preserveAspectRatio ? MIN(xRatio, yRatio) : yRatio;
    
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(xScale, yScale);
    CGSize scaledSize = CGSizeApplyAffineTransform(size, scaleTransform);
    CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(targetSize.width / 2 - scaledSize.width / 2, targetSize.height / 2 - scaledSize.height / 2);
    
    SDGraphicsBeginImageContextWithOptions(targetSize, NO, 0);
    CGContextRef context = SDGraphicsGetCurrentContext();
    
#if SD_UIKIT || SD_WATCH
    // Core Graphics coordinate system use the bottom-left, UIkit use the flipped one
    CGContextTranslateCTM(context, 0, targetSize.height);
    CGContextScaleCTM(context, 1, -1);
#endif
    
    CGContextConcatCTM(context, translationTransform);
    CGContextConcatCTM(context, scaleTransform);
    
    CGContextDrawSVGDocument(context, document);
    
    image = SDGraphicsGetImageFromCurrentImageContext();
    SDGraphicsEndImageContext();
    
    CGSVGDocumentRelease(document);
    
    return image;
}

#pragma mark - Helper

+ (BOOL)supportsVectorSVGImage {
    static dispatch_once_t onceToken;
    static BOOL supports;
    dispatch_once(&onceToken, ^{
#if SD_MAC
        // macOS 10.15+ supports SVG built-in rendering, use selector to check is more accurate
        if (NSClassFromString(NSSVGImageRepClass)) {
            supports = YES;
        } else {
            supports = NO;
        }
#else
        // iOS 13+ supports SVG built-in rendering, use selector to check is more accurate
        if ([UIImage respondsToSelector:@selector(_imageWithCGSVGDocument:)]) {
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
