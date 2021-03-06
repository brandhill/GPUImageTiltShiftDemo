//
//  GPUImageGaussianBlurFilter.m
//  GPUImageTiltShiftDemo
//
//  Created by Hill on 07/04/2017.
//  Copyright © 2017. All rights reserved.
//


#import "PGGaussianSelectiveBlurFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kPGGaussianSelectiveBlurFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; 
 
 uniform lowp float excludeCircleRadius;
 uniform lowp vec2 excludeCirclePoint;
 uniform lowp float excludeBlurSize;
 uniform highp float aspectRatio;
 uniform highp float rotation;
 uniform lowp int isRadialBlur;
 uniform lowp int isDebugging;
 
 void main()
 {
     lowp vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2);
     
     highp float distanceFromCenter;
     
     if ( isRadialBlur == 1 ) {
         // for radial blur
         highp vec2 textureCoordinateToUse = vec2(textureCoordinate2.x * aspectRatio, (textureCoordinate2.y ));
         distanceFromCenter = distance(vec2(excludeCirclePoint.x * aspectRatio, excludeCirclePoint.y), textureCoordinateToUse);
         
         if(isDebugging == 1){
             lowp float red = 0.0;
             lowp float circleBoarder = 0.005;
             
             //Draw excludeCircle
             if ((excludeCircleRadius < distanceFromCenter) && (distanceFromCenter < excludeCircleRadius + circleBoarder)){
                 red = 1.0;
             }
             lowp vec4 innerCircle = mix(blurredImageColor, vec4(red, 0.0, 0.0, 0.0), 0.2);
             
             
             gl_FragColor = mix(sharpImageColor, innerCircle, smoothstep(excludeCircleRadius - excludeBlurSize, excludeCircleRadius, distanceFromCenter));
             
         }else{
             gl_FragColor = mix(sharpImageColor, blurredImageColor, smoothstep(excludeCircleRadius - excludeBlurSize, excludeCircleRadius, distanceFromCenter));
         }
         

     } else {
         // for linear blur
         distanceFromCenter = abs((textureCoordinate2.x - excludeCirclePoint.x)*aspectRatio*cos(rotation) + (textureCoordinate2.y-excludeCirclePoint.y)*sin(rotation));
         
         
         if(isDebugging == 1){
             
             lowp float red = 0.0;
             lowp float circleBoarder = 0.005;
             
             if ((excludeCircleRadius < distanceFromCenter) && (distanceFromCenter < excludeCircleRadius + circleBoarder)){
                 red = 1.0;
             }
             
             lowp vec4 innerCircle = mix(blurredImageColor, vec4(red, 0.0, 0.0, 0.0), 0.2);
             
             gl_FragColor = mix(sharpImageColor, innerCircle, smoothstep(excludeCircleRadius - excludeBlurSize, excludeCircleRadius, distanceFromCenter));
         }else{
             gl_FragColor = mix(sharpImageColor, blurredImageColor, smoothstep(excludeCircleRadius - excludeBlurSize, excludeCircleRadius, distanceFromCenter));
         }

     }
     

 }
);
#else
NSString *const kPGGaussianSelectiveBlurFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform float excludeCircleRadius;
 uniform vec2 excludeCirclePoint;
 uniform float excludeBlurSize;
 uniform float aspectRatio;
 uniform float rotation;
 uniform float isRadialBlur;
 
 void main()
 {
     vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2);
     
     vec2 textureCoordinateToUse = vec2(textureCoordinate2.x, (textureCoordinate2.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     float distanceFromCenter = distance(excludeCirclePoint, textureCoordinateToUse);
     
     float distanceFromCenter = abs((textureCoordinate2.x - excludeCirclePoint.x) * aspectRatio*cos(rotation) + (textureCoordinate2.y-excludeCirclePoint.y)*sin(rotation));
     
     gl_FragColor = mix(sharpImageColor, blurredImageColor, smoothstep(excludeCircleRadius - excludeBlurSize, excludeCircleRadius, distanceFromCenter));
 }
);
#endif

@implementation PGGaussianSelectiveBlurFilter



- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    hasOverriddenAspectRatio = NO;
    
    // First pass: apply a variable Gaussian blur
    blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
    [self addFilter:blurFilter];
    
    // Second pass: combine the blurred image with the original sharp one
    selectiveFocusFilter = [[GPUImageTwoInputFilter alloc] initWithFragmentShaderFromString:kPGGaussianSelectiveBlurFragmentShaderString];
    [self addFilter:selectiveFocusFilter];
    
    // Texture location 0 needs to be the sharp image for both the blur and the second stage processing
    [blurFilter addTarget:selectiveFocusFilter atTextureLocation:1];
    
    // To prevent double updating of this filter, disable updates from the sharp image side    
    self.initialFilters = [NSArray arrayWithObjects:blurFilter, selectiveFocusFilter, nil];
    self.terminalFilter = selectiveFocusFilter;
    
    self.blurRadiusInPixels = 5.0;
    
    self.excludeCircleRadius = 60.0/320.0;
    self.excludeCirclePoint = CGPointMake(0.5f, 0.5f);
    self.excludeBlurSize = 30.0/320.0;
    self.isRadial = YES;
    self.isDebugging = NO;
    
    return self;
}

- (instancetype)initWithBlurFilter:(PGGaussianSelectiveBlurFilter*)filter
{
    if (!(self = [self init]))
    {
        return nil;
    }
    self.excludeCirclePoint = filter.excludeCirclePoint;
    self.excludeCircleRadius = filter.excludeCircleRadius;
    self.rotation = filter.rotation;
    self.isRadial = filter.isRadial;
    self.aspectRatio = filter.aspectRatio;
    self.blurRadiusInPixels = filter.blurRadiusInPixels;
    self.excludeBlurSize = filter.excludeBlurSize;
    
    return self;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    CGSize oldInputSize = inputTextureSize;
    [super setInputSize:newSize atIndex:textureIndex];
    inputTextureSize = newSize;
    
    if ( (!CGSizeEqualToSize(oldInputSize, inputTextureSize)) && (!hasOverriddenAspectRatio) && (!CGSizeEqualToSize(newSize, CGSizeZero)) )
    {
        _aspectRatio = (inputTextureSize.width / inputTextureSize.height);
        [selectiveFocusFilter setFloat:_aspectRatio forUniformName:@"aspectRatio"];
    }
}

#pragma mark -
#pragma mark Accessors

- (void)setBlurRadiusInPixels:(CGFloat)newValue;
{
    blurFilter.blurRadiusInPixels = newValue;
}

- (CGFloat)blurRadiusInPixels;
{
    return blurFilter.blurRadiusInPixels;
}

- (void)setExcludeCirclePoint:(CGPoint)newValue;
{
    _excludeCirclePoint = newValue;
    [selectiveFocusFilter setPoint:newValue forUniformName:@"excludeCirclePoint"];
}

- (void)setExcludeCircleRadius:(CGFloat)newValue;
{
    _excludeCircleRadius = newValue;
    [selectiveFocusFilter setFloat:newValue forUniformName:@"excludeCircleRadius"];
}

- (void)setExcludeBlurSize:(CGFloat)newValue;
{
    _excludeBlurSize = newValue;
    [selectiveFocusFilter setFloat:newValue forUniformName:@"excludeBlurSize"];
}

- (void)setAspectRatio:(CGFloat)newValue;
{
    hasOverriddenAspectRatio = YES;
    _aspectRatio = newValue;    
    [selectiveFocusFilter setFloat:_aspectRatio forUniformName:@"aspectRatio"];
}

- (void)setRotation:(CGFloat)newValue;
{
    _rotation = newValue;
    [selectiveFocusFilter setFloat:newValue forUniformName:@"rotation"];
}


- (void)setIsRadial:(BOOL)isRadial;
{
    _isRadial = isRadial;
    [selectiveFocusFilter setInteger:[NSNumber numberWithBool:_isRadial].intValue forUniformName:@"isRadialBlur"];
}

- (void)setIsDebugging:(BOOL)isDebugging;
{
    _isDebugging = isDebugging;
    [selectiveFocusFilter setInteger:[NSNumber numberWithBool:_isDebugging].intValue forUniformName:@"isDebugging"];
}

@end
