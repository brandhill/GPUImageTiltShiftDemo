//
//  PGVignetteFilter.h
//  GPUImageTiltShiftDemo
//
//  Created by Hill on 07/04/2017.
//  Copyright © 2017. All rights reserved.
//

#import <GPUImage/GPUImage.h>

/** Performs a vignetting effect, fading out the image at the edges
 */
@interface PGVignetteFilter : GPUImageFilter
{
    GLint vignetteCenterUniform, vignetteColorUniform, vignetteAlphaUniform, vignetteStartUniform;
    GLint vignetteEndUniform, rotationUniform, aspectRatioUniform;
    GLint isRadialUniform, isDebuggingUniform;
}

// the center for the vignette in tex coords (defaults to 0.5, 0.5)
@property (nonatomic, readwrite) CGPoint vignetteCenter;

// The color to use for the Vignette (defaults to black)
@property (nonatomic, readwrite) GPUVector3 vignetteColor;

// Alpha channel for color. Default of 1.0
@property (nonatomic, readwrite) CGFloat vignetteAlpha;

// The normalized distance from the center where the vignette effect starts. Default of 0.5.
@property (nonatomic, readwrite) CGFloat vignetteStart;

// The normalized distance from the center where the vignette effect ends. Default of 0.75.
@property (nonatomic, readwrite) CGFloat vignetteEnd;

@property (readwrite, nonatomic) BOOL isRadial;

@property (readwrite, nonatomic) BOOL isDebugging;

@property (readwrite, nonatomic) CGFloat rotation;

@property (readwrite, nonatomic) CGFloat aspectRatio;

- (instancetype)initWithFilter:(PGVignetteFilter*)filter;

@end
