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
    NSURL *svgURL = [NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/6/67/Firefox_Logo%2C_2017.svg"];
    NSURL *svgURL2 = [NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/2/2d/Sample_SVG_file%2C_signature.svg"];
    NSURL *svgURL3 = [NSURL URLWithString:@"https://simpleicons.org/icons/github.svg"];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    // `SVGKLayeredImageView`, best on performance and do actually vector image rendering (translate SVG to CALayer tree).
    UIImageView *imageView1 = [[UIImageView alloc] init];
    imageView1.frame = CGRectMake(0, 0, screenSize.width, screenSize.height / 2);
//    imageView1.sd_adjustContentMode = YES; // make `contentMode` works
    imageView1.contentMode = UIViewContentModeScaleAspectFill;
    imageView1.clipsToBounds = YES;
    
    // `SVGKFastImageView`, draw SVG as bitmap dynamically when size changed.
    UIImageView *imageView2 = [[UIImageView alloc] init];
    imageView2.frame = CGRectMake(0, screenSize.height / 2, screenSize.width, screenSize.height / 2);
    imageView2.clipsToBounds = YES;
    
    // `UIImageView`, draw SVG as bitmap image with fixed size, like PNG.
    UIImageView *imageView3 = [[UIImageView alloc] initWithFrame:CGRectMake(screenSize.width - 100, screenSize.height - 100, 100, 100)];
    
    [self.view addSubview:imageView1];
    [self.view addSubview:imageView2];
    [self.view addSubview:imageView3];
    
    [imageView1 sd_setImageWithURL:svgURL placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"SVGKLayeredImageView SVG load success");
            NSData *svgData = [image sd_imageDataAsFormat:SDImageFormatSVG];
            NSAssert(svgData.length > 0, @"SVG Data should exist");
        }
    }];
    [imageView2 sd_setImageWithURL:svgURL2 placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"SVGKFastImageView SVG load success");
        }
    }];
    // on iOS 13, UIImageView supports SVG vector scale. On iOS 12, this will fallback bitmap representation
    [imageView3 sd_setImageWithURL:svgURL3 placeholderImage:nil options:SDWebImageRetryFailed context:nil progress:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"SVG load animation success");
            [UIView animateWithDuration:2 animations:^{
                imageView3.bounds = CGRectMake(0, 0, 300, 300);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:2 animations:^{
                    imageView3.bounds = CGRectMake(0, 0, 100, 100);
                }];
            }];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
