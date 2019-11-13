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
    
    CGSize screenSize = self.view.bounds.size;
    
    UIImageView *imageView1 = [[UIImageView alloc] init];
    imageView1.frame = CGRectMake(0, 0, screenSize.width / 2, screenSize.height);
    imageView1.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    UIImageView *imageView2 = [[UIImageView alloc] init];
    imageView2.frame = CGRectMake(screenSize.width / 2, 0, screenSize.width / 2, screenSize.height);
    imageView2.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    [self.view addSubview:imageView1];
    [self.view addSubview:imageView2];
    
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
                NSAnimationContext *currentContext = [NSAnimationContext currentContext];
                currentContext.duration = 2;
                imageView2.animator.bounds = CGRectMake(0, 0, screenSize.width / 4, screenSize.height / 2);
            } completionHandler:^{
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                    NSAnimationContext *currentContext = [NSAnimationContext currentContext];
                    currentContext.duration = 2;
                    imageView2.animator.bounds = CGRectMake(0, 0, screenSize.width / 2, screenSize.height);
                } completionHandler:nil];
            }];
        }
    }];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
