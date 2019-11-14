//
//  ViewController.m
//  SDWebImageSVGCoder-Example-macOS
//
//  Created by lizhuoli on 2018/11/1.
//  Copyright © 2018 lizhuoli1126@126.com. All rights reserved.
//

#import "ViewController.h"
#import <SDWebImage/SDWebImage.h>
#import <SDWebImageSVGCoder/SDWebImageSVGCoder.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    SDImageSVGCoder *SVGCoder = [SDImageSVGCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:SVGCoder];
    NSURL *svgURL = [NSURL URLWithString:@"https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/w3c.svg"];
    NSURL *svgURL2 = [NSURL URLWithString:@"https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/wikimedia.svg"];
    NSURL *svgURL3 = [NSURL URLWithString:@"https://simpleicons.org/icons/github.svg"];
    
    CGSize screenSize = self.view.bounds.size;
    
    UIImageView *imageView1 = [[UIImageView alloc] init];
    imageView1.frame = CGRectMake(0, 0, screenSize.width / 2, screenSize.height);
    imageView1.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    UIImageView *imageView2 = [[UIImageView alloc] init];
    imageView2.frame = CGRectMake(screenSize.width / 2, 0, screenSize.width / 2, screenSize.height);
    imageView2.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    UIImageView *imageView3 = [[UIImageView alloc] init];
    imageView3.frame = CGRectMake(screenSize.width - 50, 0, 50, 50);
    imageView3.imageScaling = NSImageScaleAxesIndependently;
    
    [self.view addSubview:imageView1];
    [self.view addSubview:imageView2];
    [self.view addSubview:imageView3];
    
    [imageView1 sd_setImageWithURL:svgURL placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"SVG load success");
            NSData *svgData = [image sd_imageDataAsFormat:SDImageFormatSVG];
            NSAssert(svgData.length > 0, @"SVG Data should exist");
        }
    }];
    [imageView2 sd_setImageWithURL:svgURL2 placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"SVG load animation success");
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                context.duration = 2;
                imageView2.animator.bounds = CGRectMake(0, 0, screenSize.width / 4, screenSize.height / 2);
            } completionHandler:^{
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                    context.duration = 2;
                    imageView2.animator.bounds = CGRectMake(0, 0, screenSize.width / 2, screenSize.height);
                } completionHandler:nil];
            }];
        }
    }];
    [imageView3 sd_setImageWithURL:svgURL3 placeholderImage:nil options:SDWebImageRetryFailed context:@{SDWebImageContextSVGPrefersBitmap: @(YES), SDWebImageContextSVGImageSize: @(CGSizeMake(50, 50))} progress:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"SVG bitmap load success.");
            NSData *svgData = [image sd_imageDataAsFormat:SDImageFormatSVG];
            NSAssert(!svgData, @"SVG Data should not exist");
        }
    }];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
