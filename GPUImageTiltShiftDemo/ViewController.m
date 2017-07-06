//
//  ViewController.m
//  GPUImageTiltShiftDemo
//
//  Created by 杨晴贺 on 2017/5/26.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "ViewController.h"
#import "PGGaussianSelectiveBlurFilter.h"
#import "PGVignetteFilter.h"
#import <GPUImage/GPUImage.h>


@interface ViewController ()<UIGestureRecognizerDelegate>
{
    CGFloat lastScale;
    CGPoint lastPoint;
    
    CGFloat lastRotation;
    
    NSMutableSet *_activeRecognizers;
    CGFloat lastBlurScale;
    GPUImageView *primaryView;
}

@property (nonatomic , strong) GPUImagePicture *sourcePicture;
@property (nonatomic , strong) PGGaussianSelectiveBlurFilter *gaussianSelectiveBlurFilter;
@property (nonatomic , strong) PGVignetteFilter *vignetteFilter;



@property (nonatomic, strong) UIPinchGestureRecognizer        *pinchGestureRecognizer;
@property (nonatomic, strong) UIRotationGestureRecognizer     *rotateGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer          *panGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer          *tapGestureRecognizer;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    primaryView = [[GPUImageView alloc] initWithFrame:self.view.frame];

    self.view = primaryView;
    UIImage *inputImage = [UIImage imageNamed:@"face_2"];
    _sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage];

    
    [self initGaussianSelectiveBlurFilter:primaryView];
    
    
    [_sourcePicture processImage];
    
    [self initGesture];


    lastBlurScale = 1.0;
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


- (void) initGaussianSelectiveBlurFilter:(GPUImageView*)gPUImageView;
{
    _gaussianSelectiveBlurFilter = [[PGGaussianSelectiveBlurFilter alloc] init];
    
    _gaussianSelectiveBlurFilter.aspectRatio = 1;
    _gaussianSelectiveBlurFilter.blurRadiusInPixels = 50;
    _gaussianSelectiveBlurFilter.excludeCircleRadius = 0.2;
//    _gaussianSelectiveBlurFilter.excludeBlurSize = 0.3;
    _gaussianSelectiveBlurFilter.excludeCirclePoint = CGPointMake(0.5, 0.5);
    
    
//    self.blurRadiusInPixels = 5.0;
//    self.excludeCircleRadius = 60.0/320.0;
//    self.excludeBlurSize = 30.0/320.0;
//    self.excludeCirclePoint = CGPointMake(0.5f, 0.5f);

    
    //[_gaussianSelectiveBlurFilter forceProcessingAtSize:gPUImageView.sizeInPixels];
    [_gaussianSelectiveBlurFilter forceProcessingAtSizeRespectingAspectRatio:gPUImageView.sizeInPixels];
    [_sourcePicture addTarget:_gaussianSelectiveBlurFilter];
//    [_gaussianSelectiveBlurFilter addTarget:gPUImageView];
    
    
    _vignetteFilter = [[PGVignetteFilter alloc] init];
    _vignetteFilter.vignetteCenter = CGPointMake(0.5, 0.5);
    
    _vignetteFilter.vignetteColor = (GPUVector3){1.0,1.0,1.0};
    _vignetteFilter.vignetteAlpha = 0.4;
    _vignetteFilter.vignetteStart = 0.2;
    _vignetteFilter.vignetteEnd = 0.25;
    
    [_vignetteFilter forceProcessingAtSizeRespectingAspectRatio:gPUImageView.sizeInPixels];

    //[_vignetteFilter useNextFrameForImageCapture];
    
    //[_gaussianSelectiveBlurFilter addTarget:_vignetteFilter];
    //[_vignetteFilter addTarget:gPUImageView];

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


- (void)updateFilterFocusLevel:(float) level
{
    [_sourcePicture processImage];
}


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
//            if (_activeRecognizers.count == 0)
//                selectedImage.referenceTransform = selectedImage.transform;
            lastBlurScale = 1.0;
            [_activeRecognizers addObject:recognizer];
            break;
            
        case UIGestureRecognizerStateEnded:
//            selectedImage.referenceTransform = [self applyRecognizer:recognizer toTransform:selectedImage.referenceTransform];
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
                    
                    NSLog(@"handleGesture, angle : %f", angle);
                    
                    _gaussianSelectiveBlurFilter.isRadial = NO;
                    _gaussianSelectiveBlurFilter.rotation = angle;
                    
                    [_sourcePicture processImage];
                    
                }else if ([recognizer respondsToSelector:@selector(scale)]) {
//                    CGFloat scaleX = transform.a;
//                    CGFloat scaleY = transform.d;
//                    
//                    CGFloat scale = ABS(1.0 - (lastScale - MIN(scaleX, scaleY)));
//                    
//                    NSLog(@"handleGesture, scaleX : %f, scaleY : %f", scaleX, scaleY);
//                    NSLog(@"handleGesture, scale : %f", scale);
//                    
//                    lastBlurScale = scale;
//                    
//                    
//                    _gaussianSelectiveBlurFilter.excludeCircleRadius = lastBlurScale;
//                    [_sourcePicture processImage];
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

    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint point = [gesture locationInView:self.view];
        float rate = point.y / self.view.frame.size.height;
        NSLog(@"Processing : %f",rate);
        
        //[self updateFilterFocusLevel:rate];
        float pointY = point.y / self.view.frame.size.height;
        float pointX = point.x / self.view.frame.size.width;
        _gaussianSelectiveBlurFilter.excludeCirclePoint = CGPointMake(pointX, pointY);
        _vignetteFilter.vignetteCenter = CGPointMake(pointX, pointY);
        
        [_sourcePicture processImage];
    }
    
    
}

- (void)tapHandler:(UITapGestureRecognizer*)gesture
{
    CGPoint point = [gesture locationInView:self.view];
    float rate = point.y / self.view.frame.size.height;
    NSLog(@"Processing : %f",rate);
    //[self updateFilterFocusLevel:rate];
    float pointY = point.y / self.view.frame.size.height;
    float pointX = point.x / self.view.frame.size.width;
    _gaussianSelectiveBlurFilter.excludeCirclePoint = CGPointMake(pointX, pointY);
    _vignetteFilter.vignetteCenter = CGPointMake(pointX, pointY);
    
    [_sourcePicture processImage];

}

- (void)pinchHandler:(UIPinchGestureRecognizer*)gesture
{
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        //lastScale = 1.0;
        lastPoint = [gesture locationInView:self.view];
        
        NSLog(@"pinchHandler lastPoint : %@",NSStringFromCGPoint(lastPoint));

    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint curPoint = [gesture locationInView:self.view];
        
        NSLog(@"pinchHandler curPoint : %@",NSStringFromCGPoint(curPoint));
        
        CGFloat angle = [self pointPairToBearingDegrees:lastPoint secondPoint:curPoint];
        
        NSLog(@"pinchHandler angle : %f",angle);
        
        [_sourcePicture processImage];
    }
    
    // Scale
    CGFloat scale = ABS(0.5 - (lastScale - gesture.scale/10));
//    [self.layer setAffineTransform:
//     CGAffineTransformScale([self.layer affineTransform],
//                            scale,
//                            scale)];
    NSLog(@"pinchHandler scale : %f, gesture.scale : %f",scale, gesture.scale);
    
    
    lastScale = gesture.scale / 10;
    
    // Translate
//    CGPoint point = [gesture locationInView:self.view];
//    [self.layer setAffineTransform:
//     CGAffineTransformTranslate([self.layer affineTransform],
//                                point.x - lastPoint.x,
//                                point.y - lastPoint.y)];
//    CGPoint curPoint = [gesture locationInView:self.view];
//    

    
    

    
}

- (void)rotateHandler:(UIRotationGestureRecognizer*)gesture
{
    lastRotation = gesture.rotation;
 
    NSLog(@"rotateHandler lastRotation : %f",lastRotation);
 
    CGFloat currentRotation = [[gesture.view.layer valueForKeyPath:@"transform.rotation.z"] floatValue];
    
    NSLog(@"rotateHandler currentRotation : %f",currentRotation);
    
    CGFloat useRotation = gesture.rotation;
    
    while( useRotation < -M_PI )
        useRotation += M_PI*2;
    
    while( useRotation > M_PI )
        useRotation -= M_PI*2;
    
    
    CGFloat angle = useRotation * (180 / M_PI);
    
    NSLog(@"rotateHandler angle : %f", angle);
    
    _gaussianSelectiveBlurFilter.isRadial = NO;
    _gaussianSelectiveBlurFilter.rotation = angle;
    
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



@end
