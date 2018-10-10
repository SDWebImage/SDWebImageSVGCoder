//
//  SDWebImageSVGCoderDefine.m
//  SDWebImageSVGCoder
//
//  Created by lizhuoli on 2018/10/11.
//

#import "SDWebImageSVGCoderDefine.h"
#import <SVGKit/SVGKit.h>

void SDAdjustSVGContentMode(SVGKImage * svgImage, UIViewContentMode contentMode, CGSize viewSize) {
    NSCParameterAssert(svgImage);
    if (!svgImage.hasSize) {
        // `SVGKImage` does not has size, specify the content size, earily return
        svgImage.size = viewSize;
        return;
    }
    CGSize imageSize = svgImage.size;
    if (imageSize.height == 0 || viewSize.height == 0) {
        return;
    }
    CGFloat wScale = viewSize.width / imageSize.width;
    CGFloat hScale = viewSize.height / imageSize.height;
    CGFloat imageAspect = imageSize.width / imageSize.height;
    CGFloat viewAspect = viewSize.width / viewSize.height;
    CGFloat smallestScaleUp = MIN(wScale, hScale);
    CGFloat biggestScaleDown = MAX(wScale, hScale);
    CGFloat xPosition;
    CGFloat yPosition;
    
    // Geometry calculation
    switch (contentMode) {
        case UIViewContentModeScaleToFill: {
            svgImage.size = viewSize;
        }
            break;
        case UIViewContentModeScaleAspectFit: {
            CGFloat scale = smallestScaleUp < 1.0f ? smallestScaleUp : biggestScaleDown;
            CGSize targetSize = CGSizeApplyAffineTransform(imageSize, CGAffineTransformMakeScale(scale, scale));
            CGFloat x = ceil(viewSize.width - targetSize.width) / 2;
            CGFloat y = ceil(viewSize.height - targetSize.height) / 2;
            svgImage.size = targetSize;
            svgImage.DOMTree.viewport = SVGRectMake(x, y, targetSize.width, targetSize.height);
            // masksToBounds to clip the sublayer which beyond the viewport to match `UIImageView` behavior
            svgImage.CALayerTree.masksToBounds = YES;
        }
            break;
        case UIViewContentModeScaleAspectFill: {
            CGFloat scale;
            if (imageAspect < viewAspect) {
                // scale width
                scale = wScale;
            } else {
                // scale height
                scale = hScale;
            }
            CGSize targetSize = CGSizeApplyAffineTransform(imageSize, CGAffineTransformMakeScale(scale, scale));
            svgImage.size = targetSize;
            if (imageAspect < viewAspect) {
                // need center y as well
                xPosition = targetSize.width / 2;
                yPosition = viewSize.height / 2;
            } else {
                // need center x as well
                xPosition = viewSize.width / 2;
                yPosition = targetSize.height / 2;
            }
            svgImage.CALayerTree.position = CGPointMake(xPosition, yPosition);
        }
            break;
        case UIViewContentModeTop: {
            xPosition = viewSize.width / 2;
            yPosition = imageSize.height / 2;
            svgImage.CALayerTree.position = CGPointMake(xPosition, yPosition);
        }
            break;
        case UIViewContentModeTopLeft: {
            xPosition = imageSize.width / 2;
            yPosition = imageSize.height / 2;
            svgImage.CALayerTree.position = CGPointMake(xPosition, yPosition);
        }
            break;
        case UIViewContentModeTopRight: {
            xPosition = -imageSize.width / 2 + viewSize.width;
            yPosition = imageSize.height / 2;
            svgImage.CALayerTree.position = CGPointMake(xPosition, yPosition);
        }
            break;
        case UIViewContentModeCenter: {
            xPosition = viewSize.width / 2;
            yPosition = viewSize.height / 2;
            svgImage.CALayerTree.position = CGPointMake(xPosition, yPosition);
        }
            break;
        case UIViewContentModeLeft: {
            xPosition = imageSize.width / 2;
            yPosition = viewSize.height / 2;
            svgImage.CALayerTree.position = CGPointMake(xPosition, yPosition);
        }
            break;
        case UIViewContentModeRight: {
            xPosition = -imageSize.width / 2 + viewSize.width;
            yPosition = viewSize.height / 2;
            svgImage.CALayerTree.position = CGPointMake(xPosition, yPosition);
        }
            break;
        case UIViewContentModeBottom: {
            xPosition = viewSize.width / 2;
            yPosition = -imageSize.height / 2 + viewSize.height;
            svgImage.CALayerTree.position = CGPointMake(xPosition, yPosition);
        }
            break;
        case UIViewContentModeBottomLeft: {
            xPosition = imageSize.width / 2;
            yPosition = -imageSize.height / 2 + viewSize.height;
            svgImage.CALayerTree.position = CGPointMake(xPosition, yPosition);
        }
            break;
        case UIViewContentModeBottomRight: {
            xPosition = -imageSize.width / 2 + viewSize.width;
            yPosition = -imageSize.height / 2 + viewSize.height;
            svgImage.CALayerTree.position = CGPointMake(xPosition, yPosition);
        }
            break;
        case UIViewContentModeRedraw: {
            svgImage.CALayerTree.needsDisplayOnBoundsChange = YES;
        }
            break;
    }
}

SDWebImageContextOption _Nonnull const SDWebImageContextVectorImageSize = @"vectorImageSize";
