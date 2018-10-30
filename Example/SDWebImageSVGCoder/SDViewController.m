//
//  SDViewController.m
//  SDWebImageSVGCoder
//
//  Created by lizhuoli1126@126.com on 09/27/2018.
//  Copyright (c) 2018 lizhuoli1126@126.com. All rights reserved.
//

#import "SDViewController.h"
#import <SDWebImageSVGCoder/SDWebImageSVGCoder.h>
#import <SVGKit/SVGKit.h>

@interface SDViewController ()

@end

@implementation SDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    SDImageSVGCoder *SVGCoder = [SDImageSVGCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:SVGCoder];
    NSURL *svgURL = [NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/1/14/Mahuri.svg"];
    NSURL *svgURL2 = [NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/2/2d/Sample_SVG_file%2C_signature.svg"];
    NSURL *svgURL3 = [NSURL URLWithString:@"https://simpleicons.org/icons/github.svg"];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    // `SVGKLayeredImageView`, best on performance and do actually vector image rendering (translate SVG to CALayer tree).
    SVGKImageView *imageView1 = [[SVGKLayeredImageView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height / 2)];
    imageView1.sd_adjustContentMode = YES; // make `contentMode` works
    imageView1.contentMode = UIViewContentModeScaleAspectFill;
    imageView1.clipsToBounds = YES;
    
    // `SVGKFastImageView`, draw SVG as bitmap dynamically when size changed.
    SVGKImageView *imageView2 = [[SVGKFastImageView alloc] initWithFrame:CGRectMake(0, screenSize.height / 2, screenSize.width, screenSize.height / 2)];
    imageView2.clipsToBounds = YES;
    
    // `UIImageView`, draw SVG as bitmap image with fixed size, like PNG.
    UIImageView *imageView3 = [[UIImageView alloc] initWithFrame:CGRectMake(screenSize.width - 100, screenSize.height - 100, 100, 100)];
    
    [self.view addSubview:imageView1];
    [self.view addSubview:imageView2];
    [self.view addSubview:imageView3];
    
    [imageView1 sd_setImageWithURL:svgURL placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"SVGKLayeredImageView SVG load success");
        }
    }];
    [imageView2 sd_setImageWithURL:svgURL2 placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"SVGKFastImageView SVG load success");
        }
    }];
    // For `UIImageView`, you can specify a desired SVG size instead of original SVG viewport (which may be small)
    [imageView3 sd_setImageWithURL:svgURL3 placeholderImage:nil options:SDWebImageRetryFailed context:@{SDWebImageContextSVGImageSize : @(CGSizeMake(100, 100))} progress:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"UIImageView SVG load success");
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
