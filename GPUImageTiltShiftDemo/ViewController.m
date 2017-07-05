//
//  ViewController.m
//  GPUImageTiltShiftDemo
//
//  Created by 杨晴贺 on 2017/5/26.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "ViewController.h"
#import "LinearTiltShiftFilter.h"

#import <GPUImage/GPUImage.h>

@interface ViewController ()<UIGestureRecognizerDelegate>
{
    CGFloat lastScale;
    CGPoint lastPoint;
    
    CGFloat lastRotation;
}

@property (nonatomic , strong) GPUImagePicture *sourcePicture;
@property (nonatomic , strong) GPUImageTiltShiftFilter *sepiaFilter;
@property (nonatomic , strong) LinearTiltShiftFilter *linearTiltShiftFilter;

@property (nonatomic, strong) UIPinchGestureRecognizer        *pinchGestureRecognizer;
@property (nonatomic, strong) UIRotationGestureRecognizer     *rotateGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer          *panGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer          *tapGestureRecognizer;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GPUImageView *primaryView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.view = primaryView;
    UIImage *inputImage = [UIImage imageNamed:@"face"];
    _sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage];
    

    // init LinearTiltShiftFilter
    _linearTiltShiftFilter = [[LinearTiltShiftFilter alloc] init];
    _linearTiltShiftFilter.blurRadiusInPixels = 40.0;
    _linearTiltShiftFilter.focusFallOffRate = 0.1;
    [_linearTiltShiftFilter forceProcessingAtSize:primaryView.sizeInPixels];
    [_sourcePicture addTarget:_linearTiltShiftFilter];
    [_linearTiltShiftFilter addTarget:primaryView];
    
    // init GPUImageTiltShiftFilter
//    _sepiaFilter = [[GPUImageTiltShiftFilter alloc] init];
//    _sepiaFilter.blurRadiusInPixels = 40.0;
//    _sepiaFilter.focusFallOffRate = 0.1;
//    [_sepiaFilter forceProcessingAtSize:primaryView.sizeInPixels];
//    [_sourcePicture addTarget:_sepiaFilter];
//    [_sepiaFilter addTarget:primaryView];


    [_sourcePicture processImage];
    
    [self initGesture];
    
    // GPUImageContext相关的数据显示
    GLint size = [GPUImageContext maximumTextureSizeForThisDevice];
    GLint unit = [GPUImageContext maximumTextureUnitsForThisDevice];
    GLint vector = [GPUImageContext maximumVaryingVectorsForThisDevice];
    NSLog(@"%d %d %d", size, unit, vector);
}

#pragma mark - Private method

- (void) initGesture
{

    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    _tapGestureRecognizer.delegate = self;
    
    _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchHandler:)];
    _pinchGestureRecognizer.delegate = self;
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandler:)];
    _panGestureRecognizer.maximumNumberOfTouches = 1;
    _panGestureRecognizer.delegate = self;
    
    _rotateGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateHandler:)];
    _rotateGestureRecognizer.delegate = self;
    

    
    [self.view addGestureRecognizer:_panGestureRecognizer];
    [self.view addGestureRecognizer:_tapGestureRecognizer];

    [self.view addGestureRecognizer:_pinchGestureRecognizer];
//    [self.view addGestureRecognizer:_rotateGestureRecognizer];
    
}



- (void)updateFilterFocusLevel:(float) level
{
    [_linearTiltShiftFilter setTopFocusLevel:level];
    [_linearTiltShiftFilter setBottomFocusLevel:level];
    
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

- (void)panHandler:(UIPanGestureRecognizer*)gesture
{

    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint point = [gesture locationInView:self.view];
        float rate = point.y / self.view.frame.size.height;
        NSLog(@"Processing : %f",rate);
        
        [self updateFilterFocusLevel:rate];
    }
    
    
}

- (void)tapHandler:(UITapGestureRecognizer*)gesture
{
    CGPoint point = [gesture locationInView:self.view];
    float rate = point.y / self.view.frame.size.height;
    NSLog(@"Processing : %f",rate);
    [self updateFilterFocusLevel:rate];

}

- (void)pinchHandler:(UIPinchGestureRecognizer*)gesture
{
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        //lastScale = 1.0;
        lastPoint = [gesture locationInView:self.view];

    }
    
    // Scale
    CGFloat scale = ABS(0.5 - (lastScale - gesture.scale/10));
//    [self.layer setAffineTransform:
//     CGAffineTransformScale([self.layer affineTransform],
//                            scale,
//                            scale)];
    NSLog(@"pinch scale : %f, gesture.scale : %f",scale, gesture.scale);
    
    
    lastScale = gesture.scale / 10;
    
    // Translate
//    CGPoint point = [gesture locationInView:self.view];
//    [self.layer setAffineTransform:
//     CGAffineTransformTranslate([self.layer affineTransform],
//                                point.x - lastPoint.x,
//                                point.y - lastPoint.y)];
    lastPoint = [gesture locationInView:self.view];
    
    _linearTiltShiftFilter.focusFallOffRate = scale;
    [_sourcePicture processImage];
    
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
    
    _linearTiltShiftFilter.angleRate = angle;
    [_sourcePicture processImage];
}


#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}


//- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    UITouch* touch = [touches anyObject];
//    CGPoint point = [touch locationInView:self.view];
//    float rate = point.y / self.view.frame.size.height;
//    NSLog(@"%f",rate);
//    
//    NSLog(@"Processing");
//    
//    //[_sepiaFilter setTopFocusLevel:rate];
//    //[_sepiaFilter setBottomFocusLevel:rate];
//    
//    [_linearTiltShiftFilter setTopFocusLevel:rate];
//    [_linearTiltShiftFilter setBottomFocusLevel:rate];
//    
//    [_sourcePicture processImage];
//}



@end
