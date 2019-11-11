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
static CGSVGDocumentRef (*CGSVGDocumentCreateFromDataProvider)(CGDataProviderRef provider, CFDictionaryRef options);
static CGSVGDocumentRef (*CGSVGDocumentRetain)(CGSVGDocumentRef);
static void (*CGSVGDocumentRelease)(CGSVGDocumentRef);
static void (*CGSVGDocumentWriteToData)(CGSVGDocumentRef document, CFDataRef data, CFDictionaryRef options);

#if SD_UIKIT

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

@protocol NSSVGImageRepProtocol <NSObject>

- (instancetype)initWithSVGDocument:(CGSVGDocumentRef)document;
- (instancetype)initWithData:(NSData *)data;
- (CGSVGDocumentRef)_document;

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
    CGSVGDocumentWriteToData = dlsym(RTLD_DEFAULT, "CGSVGDocumentWriteToData");
}

#pragma mark - Decode

- (BOOL)canDecodeFromData:(NSData *)data {
    return [self.class isSVGFormatForData:data];
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    if (![self.class supportsVectorSVGImage]) {
        return nil;
    }
    // Parse args
    SDWebImageContext *context = options[SDImageCoderWebImageContext];
    NSValue *sizeValue = context[SDWebImageContextSVGImageSize];
    #if SD_MAC
    CGSize imageSize = sizeValue.sizeValue;
    #else
    CGSize imageSize = sizeValue.CGSizeValue;
    #endif
    
#if SD_MAC
    Class imageRepClass = NSClassFromString(NSSVGImageRepClass);
    NSImageRep *imageRep = [[imageRepClass alloc] initWithData:data];
    if (!imageRep) {
        return nil;
    }
    NSImage *image = [[NSImage alloc] initWithSize:imageSize];
    [image addRepresentation:imageRep];
#else
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
#endif
    return image;
}

#pragma mark - Encode

- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return format == SDImageFormatSVG;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(SDImageCoderOptions *)options {    // SVGKImage wrapper
    if (![self.class supportsVectorSVGImage]) {
        return nil;
    }
    NSMutableData *data = [NSMutableData data];
    CGSVGDocumentRef document = NULL;
#if SD_MAC
    NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
    NSImageRep *imageRep = [image bestRepresentationForRect:imageRect context:nil hints:nil];
    if ([imageRep isKindOfClass:NSClassFromString(NSSVGImageRepClass)]) {
        Ivar ivar = class_getInstanceVariable(imageRep.class, "_document");
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
