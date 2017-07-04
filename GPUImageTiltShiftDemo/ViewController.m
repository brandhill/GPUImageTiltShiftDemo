//
//  ViewController.m
//  GPUImageTiltShiftDemo
//
//  Created by 杨晴贺 on 2017/5/26.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "ViewController.h"

#import <GPUImage/GPUImage.h>

@interface ViewController ()

@property (nonatomic , strong) GPUImagePicture *sourcePicture;
@property (nonatomic , strong) GPUImageTiltShiftFilter *sepiaFilter;
@property (nonatomic , strong) GPUImageGaussianBlurFilter *blurFilter;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GPUImageView *primaryView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.view = primaryView;
    UIImage *inputImage = [UIImage imageNamed:@"face"];
    _sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage];
    _sepiaFilter = [[GPUImageTiltShiftFilter alloc] init];
    _sepiaFilter.blurRadiusInPixels = 40.0;
    _sepiaFilter.focusFallOffRate = 0.1;

    
//    _blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
//    _blurFilter.blurRadiusInPixels = 50;
//    [_blurFilter forceProcessingAtSize:primaryView.sizeInPixels];
//    [_sourcePicture addTarget:_blurFilter];
//    [_blurFilter addTarget:primaryView];
    
    
    [_sepiaFilter forceProcessingAtSize:primaryView.sizeInPixels];
    [_sourcePicture addTarget:_sepiaFilter];
    [_sepiaFilter addTarget:primaryView];

    
    [_sourcePicture processImage];
    
    
    // GPUImageContext相关的数据显示
    GLint size = [GPUImageContext maximumTextureSizeForThisDevice];
    GLint unit = [GPUImageContext maximumTextureUnitsForThisDevice];
    GLint vector = [GPUImageContext maximumVaryingVectorsForThisDevice];
    NSLog(@"%d %d %d", size, unit, vector);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    float rate = point.y / self.view.frame.size.height;
    NSLog(@"%f",rate);
    
    NSLog(@"Processing");
  

    
    [_sepiaFilter setTopFocusLevel:rate];
    [_sepiaFilter setBottomFocusLevel:rate];
    [_sourcePicture processImage];
}



@end
