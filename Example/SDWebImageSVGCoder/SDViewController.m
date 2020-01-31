//
//  SDViewController.m
//  SDWebImageSVGCoder
//
//  Created by lizhuoli1126@126.com on 09/27/2018.
//  Copyright (c) 2018 lizhuoli1126@126.com. All rights reserved.
//

#import "SDViewController.h"
#import <SDWebImageSVGCoder/SDWebImageSVGCoder.h>

@interface SDViewController ()

@end

@implementation SDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    SDImageSVGCoder *SVGCoder = [SDImageSVGCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:SVGCoder];
    NSURL *svgURL = [NSURL URLWithString:@"https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/w3c.svg"];
    NSURL *svgURL2 = [NSURL URLWithString:@"https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/wikimedia.svg"];
    NSURL *svgURL3 = [NSURL URLWithString:@"https://simpleicons.org/icons/github.svg"];
    
    CGSize screenSize = self.view.bounds.size;
    
    UIImageView *imageView1 = [[UIImageView alloc] init];
    imageView1.frame = CGRectMake(0, 0, screenSize.width, screenSize.height / 2);
    imageView1.contentMode = UIViewContentModeScaleAspectFit;
    imageView1.clipsToBounds = YES;
    
    UIImageView *imageView2 = [[UIImageView alloc] init];
    imageView2.frame = CGRectMake(0, screenSize.height / 2, screenSize.width, screenSize.height / 2);
    imageView2.contentMode = UIViewContentModeScaleAspectFit;
    imageView2.clipsToBounds = YES;
    
    UIImageView *imageView3 = [[UIImageView alloc] init];
    imageView3.frame = CGRectMake(screenSize.width - 100, screenSize.height - 100, 100, 100);
    imageView3.contentMode = UIViewContentModeScaleToFill;
    
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
            [UIView animateWithDuration:2 animations:^{
                imageView2.bounds = CGRectMake(0, 0, screenSize.width * 2, screenSize.height);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:2 animations:^{
                    imageView2.bounds = CGRectMake(0, 0, screenSize.width, screenSize.height / 2);
                }];
            }];
        }
    }];
    [imageView3 sd_setImageWithURL:svgURL3 placeholderImage:nil options:SDWebImageRetryFailed context:@{SDWebImageContextImageThumbnailPixelSize: @(CGSizeMake(100, 100))} progress:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"SVG bitmap load success.");
            NSData *svgData = [image sd_imageDataAsFormat:SDImageFormatSVG];
            NSAssert(!svgData, @"SVG Data should not exist");
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
