//
//  PGVignetteFilter.m
//  GPUImageTiltShiftDemo
//
//  Created by Hill on 07/04/2017.
//  Copyright © 2017. All rights reserved.
//

#import "PGVignetteFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kPGVignetteFragmentShaderString = SHADER_STRING

(
 uniform sampler2D inputImageTexture;
 varying highp vec2 textureCoordinate;
 
 uniform lowp vec2 vignetteCenter;
 uniform lowp vec3 vignetteColor;
 uniform lowp float vignetteAlpha;
 uniform highp float vignetteStart;
 uniform highp float vignetteEnd;
 
 uniform highp float aspectRatio;
 uniform highp float rotation;
 uniform lowp int isRadial;
 
 void main()
 {
     lowp vec4 sourceImageColor = texture2D(inputImageTexture, textureCoordinate);
     
     
     if ( isRadial == 1 ) {
         // for radial blur
         lowp float d = distance(textureCoordinate, vec2(vignetteCenter.x, vignetteCenter.y));
         lowp float percent = smoothstep(vignetteStart, vignetteEnd, d);
         
         gl_FragColor = vec4(mix(sourceImageColor.rgb, vignetteColor, vignetteAlpha * percent), sourceImageColor.a);
     }else{
         // for linear blur
         
         lowp float d = abs((textureCoordinate.x - vignetteCenter.x)*aspectRatio*cos(rotation) + (textureCoordinate.y-vignetteCenter.y)*sin(rotation));
         lowp float percent = smoothstep(vignetteStart, vignetteEnd, d);
         
         gl_FragColor = vec4(mix(sourceImageColor.rgb, vignetteColor, vignetteAlpha * percent), sourceImageColor.a);
         
     }
 }
);
#else
NSString *const kPGVignetteFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying vec2 textureCoordinate;
 
 uniform vec2 vignetteCenter;
 uniform vec3 vignetteColor;
 uniform float vignetteAlpha;
 uniform float vignetteStart;
 uniform float vignetteEnd;
 
 void main()
 {
     vec4 sourceImageColor = texture2D(inputImageTexture, textureCoordinate);
     float d = distance(textureCoordinate, vec2(vignetteCenter.x, vignetteCenter.y));
     float percent = smoothstep(vignetteStart, vignetteEnd, d);
     gl_FragColor = vec4(mix(sourceImageColor.rgb, vignetteColor, vignetteAlpha * percent), sourceImageColor.a);
 }
);
#endif

@implementation PGVignetteFilter

@synthesize vignetteCenter = _vignetteCenter;
@synthesize vignetteColor = _vignetteColor;
@synthesize vignetteAlpha =_vignetteAlpha;
@synthesize vignetteStart =_vignetteStart;
@synthesize vignetteEnd = _vignetteEnd;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kPGVignetteFragmentShaderString]))
    {
        return nil;
    }
    
    vignetteCenterUniform = [filterProgram uniformIndex:@"vignetteCenter"];
    vignetteColorUniform = [filterProgram uniformIndex:@"vignetteColor"];
    vignetteAlphaUniform = [filterProgram uniformIndex:@"vignetteAlpha"];
    vignetteStartUniform = [filterProgram uniformIndex:@"vignetteStart"];
    vignetteEndUniform = [filterProgram uniformIndex:@"vignetteEnd"];
    isRadialUniform = [filterProgram uniformIndex:@"isRadial"];
    rotationUniform = [filterProgram uniformIndex:@"rotation"];
    aspectRatioUniform = [filterProgram uniformIndex:@"aspectRatio"];
    
    self.vignetteCenter = (CGPoint){ 0.5f, 0.5f };
    self.vignetteColor = (GPUVector3){ 0.0f, 0.0f, 0.0f };
    self.vignetteAlpha = 1.0;
    self.vignetteStart = 0.3;
    self.vignetteEnd = 0.75;
    self.isRadial = YES;
    self.rotation = 0.0;
    self.aspectRatio = 1;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setVignetteCenter:(CGPoint)newValue
{
    _vignetteCenter = newValue;
    
    [self setPoint:newValue forUniform:vignetteCenterUniform program:filterProgram];
}

- (void)setVignetteColor:(GPUVector3)newValue
{
    _vignetteColor = newValue;
    
    [self setVec3:newValue forUniform:vignetteColorUniform program:filterProgram];
}


- (void)setVignetteAlpha:(CGFloat)newValue;
{
    _vignetteAlpha = newValue;
    
    [self setFloat:_vignetteAlpha forUniform:vignetteAlphaUniform program:filterProgram];
}

- (void)setVignetteStart:(CGFloat)newValue;
{
    _vignetteStart = newValue;
    
    [self setFloat:_vignetteStart forUniform:vignetteStartUniform program:filterProgram];
}

- (void)setVignetteEnd:(CGFloat)newValue;
{
    _vignetteEnd = newValue;
    
    [self setFloat:_vignetteEnd forUniform:vignetteEndUniform program:filterProgram];
}

- (void)setIsRadial:(BOOL)isRadial;
{
    _isRadial = isRadial;
    [self setInteger:[NSNumber numberWithBool:_isRadial].intValue forUniform:isRadialUniform program:filterProgram];
}

- (void)setRotation:(CGFloat)newValue;
{
    _rotation = newValue;
    [self setFloat:_rotation forUniform:rotationUniform program:filterProgram];
}

- (void)setAspectRatio:(CGFloat)newValue;
{
    _aspectRatio = newValue;
    [self setFloat:_aspectRatio forUniform:aspectRatioUniform program:filterProgram];
    
}

@end
