//
//  LinearTiltShiftFilter.h
//  GPUImageTiltShiftDemo
//
//  Created by Hill on 07/04/2017.
//  Copyright © 2017. All rights reserved.
//

#import <GPUImage/GPUImage.h>
@class GPUImageGaussianBlurFilter;

/// A simulated tilt shift lens effect
@interface LinearTiltShiftFilter : GPUImageFilterGroup
{
    GPUImageGaussianBlurFilter *blurFilter;
    GPUImageFilter *tiltShiftFilter;
}

/// The radius of the underlying blur, in pixels. This is 7.0 by default.
@property(readwrite, nonatomic) CGFloat blurRadiusInPixels; //模糊强度值（最佳为1.0-6.0 ,值太大效率会变的越来越低）

/// The normalized location of the top of the in-focus area in the image, this value should be lower than bottomFocusLevel, default 0.4
@property(readwrite, nonatomic) CGFloat topFocusLevel;    //清晰范围开始值（范围：0,1）

/// The normalized location of the bottom of the in-focus area in the image, this value should be higher than topFocusLevel, default 0.6
@property(readwrite, nonatomic) CGFloat bottomFocusLevel; //清晰范围结束值（范围：0,1）

/// The rate at which the image gets blurry away from the in-focus region, default 0.2
@property(readwrite, nonatomic) CGFloat focusFallOffRate; //模糊边界宽度（默认给0.2左右）

@property(readwrite, nonatomic) CGFloat angleRate;        //角度（0.0为垂直方向;0.5为45度角,斜线为东北方向, 1.0为水平方向）

@end
