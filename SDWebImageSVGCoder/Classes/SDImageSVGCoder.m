//
//  SDImageSVGCoder.m
//  SDWebImageSVGCoder
//
//  Created by lizhuoli on 2018/9/27.
//

#import "SDImageSVGCoder.h"
#import <SVGKit/SVGKit.h>

#define kXMLTagStart @"<?xml"
#define kSVGTagEnd @"</svg>"

@implementation SDImageSVGCoder

+ (SDImageSVGCoder *)sharedCoder {
    static dispatch_once_t onceToken;
    static SDImageSVGCoder *coder;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageSVGCoder alloc] init];
    });
    return coder;
}

#pragma mark - Decode

- (BOOL)canDecodeFromData:(NSData *)data {
    return [self.class isSVGFormatForData:data];
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    // Parse SVG
    SVGKImage *svgImage = [[SVGKImage alloc] initWithData:data];
    if (!svgImage) {
        return nil;
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
    return NO;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(SDImageCoderOptions *)options {
    return nil;
}

#pragma mark - Helper

+ (BOOL)isSVGFormatForData:(NSData *)data {
    if (!data) {
        return NO;
    }
    if (data.length <= 100) {
        return NO;
    }
    // Check start with XML tag
    NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 100)] encoding:NSASCIIStringEncoding];
    if (![testString containsString:kXMLTagStart]) {
        return NO;
    }
    // Check end with SVG tag
    testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(data.length - 100, 100)] encoding:NSASCIIStringEncoding];
    if (![testString containsString:kSVGTagEnd]) {
        return NO;
    }
    return YES;
}

@end
