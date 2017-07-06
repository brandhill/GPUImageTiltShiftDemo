//
//  ViewController.m
//  GPUImageTiltShiftDemo
//
//  Created by Hill on 07/04/2017.
//  Copyright © 2017. All rights reserved.
//

#import "ViewController.h"
#import "PGGaussianSelectiveBlurFilter.h"
#import "PGVignetteFilter.h"
#import <GPUImage/GPUImage.h>


const CGFloat kInitScaleValue = 0.2;
const CGFloat kVignetteOffset = 0.2;
const CGFloat kVignetteAlphaValue = 0.85;
const CGFloat kMaxScale = 10.0;
const CGFloat kMinScale = 0.0;

@interface ViewController ()<UIGestureRecognizerDelegate>
{
    CGFloat lastScale;
    CGPoint lastPoint;
    
    CGFloat lastRotation;
    
    NSMutableSet *_activeRecognizers;

    GPUImageView *primaryView;
    
    
}

@property (nonatomic , strong) GPUImagePicture *sourcePicture;
@property (nonatomic , strong) PGGaussianSelectiveBlurFilter *gaussianSelectiveBlurFilter;
@property (nonatomic , strong) PGVignetteFilter *vignetteFilter;

@property (nonatomic, strong) UIPinchGestureRecognizer        *pinchGestureRecognizer;
@property (nonatomic, strong) UIRotationGestureRecognizer     *rotateGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer          *panGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer          *tapGestureRecognizer;
@property (nonatomic) NSTimeInterval startFadeOutReferenceTime;

@property (nonatomic, strong) CADisplayLink *vignetteFadeOutTimer;

@property (nonatomic, assign) BOOL isVignetteFadeOutTimerRunning;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    primaryView = [[GPUImageView alloc] initWithFrame:self.view.frame];

    self.view = primaryView;
    UIImage *inputImage = [UIImage imageNamed:@"face_2"];
    _sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage];
    

    lastScale = kInitScaleValue;
    [self initFilters:primaryView];
    [self createVignetteFadeOutTimer];
    
    [_sourcePicture processImage];
    
    [self initGesture];
    
    _activeRecognizers = [NSMutableSet set];
    
    // GPUImageContext相关的数据显示
    GLint size = [GPUImageContext maximumTextureSizeForThisDevice];
    GLint unit = [GPUImageContext maximumTextureUnitsForThisDevice];
    GLint vector = [GPUImageContext maximumVaryingVectorsForThisDevice];
    NSLog(@"%d %d %d", size, unit, vector);
}

#pragma mark - init method


- (void) initGesture
{
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    _tapGestureRecognizer.delegate = self;
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandler:)];
    _panGestureRecognizer.maximumNumberOfTouches = 1;
    _panGestureRecognizer.delegate = self;
    
    _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    _pinchGestureRecognizer.delegate = self;
    
    _rotateGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    _rotateGestureRecognizer.delegate = self;
    

    
    [self.view addGestureRecognizer:_panGestureRecognizer];
    [self.view addGestureRecognizer:_tapGestureRecognizer];
    
    [self.view addGestureRecognizer:_pinchGestureRecognizer];
    [self.view addGestureRecognizer:_rotateGestureRecognizer];
    
}


- (void) initFilters:(GPUImageView*)gPUImageView;
{
    _gaussianSelectiveBlurFilter = [[PGGaussianSelectiveBlurFilter alloc] init];
    
    CGSize inputSize = CGSizeMake(MIN(gPUImageView.sizeInPixels.height, gPUImageView.sizeInPixels.width), MIN(gPUImageView.sizeInPixels.height, gPUImageView.sizeInPixels.width));
    
    _gaussianSelectiveBlurFilter.aspectRatio = 1;
    _gaussianSelectiveBlurFilter.blurRadiusInPixels = 4.5;
    _gaussianSelectiveBlurFilter.excludeCircleRadius = kInitScaleValue;
    _gaussianSelectiveBlurFilter.excludeCirclePoint = CGPointMake(0.5, 0.5);
    [_gaussianSelectiveBlurFilter forceProcessingAtSizeRespectingAspectRatio:inputSize];
    [_sourcePicture addTarget:_gaussianSelectiveBlurFilter];

    
    
    _vignetteFilter = [[PGVignetteFilter alloc] init];
    _vignetteFilter.vignetteCenter = CGPointMake(0.5, 0.5);
    _vignetteFilter.vignetteColor = (GPUVector3){1.0,1.0,1.0};
    _vignetteFilter.vignetteAlpha = 0.0f;
    _vignetteFilter.vignetteStart = 0.1;
    _vignetteFilter.vignetteEnd = 0.35;
    [_vignetteFilter forceProcessingAtSizeRespectingAspectRatio:inputSize];


    [self addVignetteFilter];
}

- (void) addVignetteFilter
{
    [_gaussianSelectiveBlurFilter removeTarget:primaryView];
    
    [_gaussianSelectiveBlurFilter addTarget:_vignetteFilter];
    [_vignetteFilter addTarget:primaryView];
}

- (void) removeVignetteFilter
{
    [_vignetteFilter removeTarget:primaryView];
    
    [_gaussianSelectiveBlurFilter removeTarget:_vignetteFilter];
    [_gaussianSelectiveBlurFilter addTarget:primaryView];
}


#pragma mark - Private method

- (CGFloat) pointPairToBearingDegrees:(CGPoint)startingPoint secondPoint:(CGPoint) endingPoint
{
    CGPoint originPoint = CGPointMake(endingPoint.x - startingPoint.x, endingPoint.y - startingPoint.y); // get origin point to origin by subtracting end from start
    float bearingRadians = atan2f(originPoint.y, originPoint.x); // get bearing in radians
    float bearingDegrees = bearingRadians * (180.0 / M_PI); // convert to degrees
    bearingDegrees = (bearingDegrees > 0.0 ? bearingDegrees : (360.0 + bearingDegrees)); // correct discontinuity
    return bearingDegrees;
}

#pragma mark - Gesture Recognizer action


- (void)handleGesture:(UIGestureRecognizer *)recognizer
{
    
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            
            if([self isVignetteFadeOutTimerRunning]){
                [self stopVignetteFadeOutTimer];
            }
            
            _vignetteFilter.vignetteAlpha = kVignetteAlphaValue;
            [_sourcePicture processImage];
            
            
            [_activeRecognizers addObject:recognizer];
            
            
            if ([recognizer respondsToSelector:@selector(scale)]) {
                CGAffineTransform transform = [self applyRecognizer:recognizer];
                CGFloat scaleX = transform.a;
                CGFloat scaleY = transform.d;
                CGFloat minScale = MIN(scaleX, scaleY);
                
                CGFloat currentScale = [[[recognizer view].layer valueForKeyPath:@"transform.scale"] floatValue];
                
                // Constants to adjust the max/min values of zoom

                
                CGFloat newScale = 1 -  (lastScale - minScale);
                newScale = MIN(newScale, kMaxScale / currentScale);
                newScale = MAX(newScale, kMinScale / currentScale);
                
                lastScale = newScale/kMaxScale;  // Store the previous scale factor for the next pinch gesture call

            }
            
            
            break;
            
        case UIGestureRecognizerStateEnded:
            
            if(![self isVignetteFadeOutTimerRunning]){
                [self startVignetteFadeOutTimer];
            }
            
            
            if ([recognizer respondsToSelector:@selector(rotation)]){
                CGAffineTransform transform = [self applyRecognizer:recognizer];
                lastRotation = atan2f(transform.b, transform.a);
                NSLog(@"handleGesture lastRotation : %f", lastRotation);
            }
            
            [_activeRecognizers removeObject:recognizer];
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGAffineTransform transform;
            for (UIGestureRecognizer *recognizer in _activeRecognizers){
                //transform = [self applyRecognizer:recognizer toTransform:transform];
                transform = [self applyRecognizer:recognizer];
                
                if ([recognizer respondsToSelector:@selector(rotation)]){
                    CGFloat angle = atan2f(transform.b, transform.a);
                    //angle = angle * (180 / M_PI);
                    angle += lastRotation;
                    NSLog(@"handleGesture, angle : %f", angle);
                    
                    _gaussianSelectiveBlurFilter.isRadial = NO;
                    _gaussianSelectiveBlurFilter.rotation = angle;
                    
                    _vignetteFilter.isRadial = NO;
                    _vignetteFilter.rotation = angle;
                    
                    [_sourcePicture processImage];
                    
                }else if ([recognizer respondsToSelector:@selector(scale)]) {
                    
                    CGFloat scaleX = transform.a;
                    CGFloat scaleY = transform.d;
                    CGFloat minScale = MIN(scaleX, scaleY);
                    
                    CGFloat currentScale = [[[recognizer view].layer valueForKeyPath:@"transform.scale"] floatValue];
                    
                    // Constants to adjust the max/min values of zoom
                    
                    CGFloat newScale = 1 -  (lastScale - minScale);
                    newScale = MIN(newScale, kMaxScale / currentScale);
                    newScale = MAX(newScale, kMinScale / currentScale);
                   
                    lastScale = newScale/kMaxScale;  // Store the previous scale factor for the next pinch gesture call

                    
                    NSLog(@"handleGesture, scale : %f", lastScale);
                    _gaussianSelectiveBlurFilter.excludeCircleRadius = lastScale;
                    
                    _vignetteFilter.vignetteStart = lastScale;
                    _vignetteFilter.vignetteEnd = lastScale + kVignetteOffset;
                    
                    [_sourcePicture processImage];
                }
            }

            break;
        }
            
        default:
            break;
    }
}

- (CGAffineTransform)applyRecognizer:(UIGestureRecognizer *)recognizer
{
    if ([recognizer respondsToSelector:@selector(rotation)]){
        return CGAffineTransformRotate(self.view.transform, [(UIRotationGestureRecognizer *)recognizer rotation]);
    }else if ([recognizer respondsToSelector:@selector(scale)]) {
        CGFloat scale = [(UIPinchGestureRecognizer *)recognizer scale];
        return CGAffineTransformScale(self.view.transform, scale, scale);
    }
    
    return CGAffineTransformIdentity;
}


- (void)panHandler:(UIPanGestureRecognizer*)gesture
{

    if (gesture.state == UIGestureRecognizerStateBegan) {

        if([self isVignetteFadeOutTimerRunning]){
            [self stopVignetteFadeOutTimer];
        }
        
        _vignetteFilter.vignetteAlpha = kVignetteAlphaValue;
        [_sourcePicture processImage];
        
    }else if (gesture.state == UIGestureRecognizerStateEnded) {

        if(![self isVignetteFadeOutTimerRunning]){
            [self startVignetteFadeOutTimer];
        }

    }else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint point = [gesture locationInView:self.view];
        
        float pointX = point.x / self.view.frame.size.width;
        float pointY = point.y / self.view.frame.size.height;
        
        NSLog(@"panHandler pointX : %f, pointY : %f",pointX, pointY);
        
        _gaussianSelectiveBlurFilter.excludeCirclePoint = CGPointMake(pointX, pointY);
        _vignetteFilter.vignetteCenter = CGPointMake(pointX, pointY);
        
        [_sourcePicture processImage];
    }
    
    
}

- (void)tapHandler:(UITapGestureRecognizer*)gesture
{
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        
        if([self isVignetteFadeOutTimerRunning]){
            [self stopVignetteFadeOutTimer];
        }
        
        _vignetteFilter.vignetteAlpha = kVignetteAlphaValue;
        [_sourcePicture processImage];
        
    }else if (gesture.state == UIGestureRecognizerStateEnded) {
        if(![self isVignetteFadeOutTimerRunning]){
            [self startVignetteFadeOutTimer];
        }
    }
    
    CGPoint point = [gesture locationInView:self.view];
    float pointX = point.x / self.view.frame.size.width;
    float pointY = point.y / self.view.frame.size.height;
    
    NSLog(@"tapHandler pointX : %f, pointY : %f",pointX, pointY);
    
    _gaussianSelectiveBlurFilter.excludeCirclePoint = CGPointMake(pointX, pointY);
    _vignetteFilter.vignetteCenter = CGPointMake(pointX, pointY);
    
    [_sourcePicture processImage];

}



#pragma mark - <UIGestureRecognizerDelegate>

//- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
//{
//    return YES;
//}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}




#pragma mark - Selfie Timer (CADisplayLink)

- (void)createVignetteFadeOutTimer
{
    _vignetteFadeOutTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(processVignetteFadeOutTimerAnimation)];
    [_vignetteFadeOutTimer setFrameInterval:1];
    [_vignetteFadeOutTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // start in stopping state
    _vignetteFadeOutTimer.paused = YES;

}
- (void)startVignetteFadeOutTimer
{
    if(_vignetteFadeOutTimer){
        self.startFadeOutReferenceTime = [NSDate timeIntervalSinceReferenceDate];;
        _vignetteFadeOutTimer.paused = NO;
        
        _isVignetteFadeOutTimerRunning = YES;
    }
}

- (void)stopVignetteFadeOutTimer
{
    if(_vignetteFadeOutTimer){
        _vignetteFadeOutTimer.paused = YES;
        
        _isVignetteFadeOutTimerRunning = NO;
    }
}




- (void)releaseVignetteFadeOutTimer
{
    if(_vignetteFadeOutTimer){
        [_vignetteFadeOutTimer invalidate];
        _vignetteFadeOutTimer = nil;
    }
}

- (void) processVignetteFadeOutTimerAnimation
{
    
    if(!_isVignetteFadeOutTimerRunning){
        return;
    }
    
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    CGFloat timeDiff = (now - self.startFadeOutReferenceTime);
    CGFloat timerValue = 1.0;
  
    
    if (timeDiff/timerValue <= 1){
        _vignetteFilter.vignetteAlpha = kVignetteAlphaValue * (1 - timeDiff/timerValue);
        [_sourcePicture processImage];
    }else{
        [self stopVignetteFadeOutTimer];
    }
    
}

@end
