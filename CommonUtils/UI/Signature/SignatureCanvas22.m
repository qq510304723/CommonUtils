//
//  WDSignatureCanvas22.m
//  CommonUtils
//
//  Created by lihuaguang on 2019/6/28.
//  Copyright © 2019 lihuaguang. All rights reserved.
//
//  学习网址: https://www.jianshu.com/p/f9b1162e62cf

#import "SignatureCanvas22.h"
#import "SignatureHelper.h"

#define             STROKE_WIDTH_MIN 0.004 // Stroke width determined by touch velocity
#define             STROKE_WIDTH_MAX 0.030
#define       STROKE_WIDTH_SMOOTHING 0.5   // Low pass filter alpha

#define           VELOCITY_CLAMP_MIN 20
#define           VELOCITY_CLAMP_MAX 5000

#define QUADRATIC_DISTANCE_TOLERANCE 3.0 // Minimum distance to make a curve
#define WIDTH_THRES_MAX 10.0f

//这个控制笔锋的控制值
#define  DIS_VEL_CAL_FACTOR 0.02f

@interface SignatureCanvas22 ()

@property (nonatomic, strong) NSMutableArray *allLayers;

//@property (nonatomic, assign) CGPoint lastPoint;

@property (nonatomic, assign) CGPoint lastPoint;
@property (nonatomic, assign) CGPoint previousPoint;

@property (nonatomic, assign) float lastVelocity;
@property (nonatomic, assign) float lastWidth;

@end

@implementation SignatureCanvas22

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _allLayers = [NSMutableArray array];
    }
    return self;
}

- (void)undo {
    if (![self canUnDo]) {
        return;
    }
}

- (void)eraser {
    if (![self canUnDo]) {
        return;
    }
    
    [self.allLayers removeAllObjects];
    
    NSArray *layers = [self.layer.sublayers copy];
    for (CALayer *layer in layers) {
        [layer removeFromSuperlayer];
    }
}

- (BOOL)canUnDo {
    return (self.allLayers.count > 0);
}

#pragma mark - Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = (UITouch *)[touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    
    NSMutableArray *points = [NSMutableArray array];
    [self.allLayers addObject:points];
    
    self.lastPoint = currentPoint;
    self.lastVelocity = 0;
    self.lastWidth = 2;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = (UITouch *)[touches anyObject];
    [self drawLineWithTouch:touch];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = (UITouch *)[touches anyObject];
    [self drawLineWithTouch:touch];
}

- (void)drawLineWithTouch:(UITouch *)touch {
    CGPoint curPoint = [touch locationInView:self];
    CGPoint prePoint = [touch previousLocationInView:self];
    CGPoint midPoint = (CGPoint){(curPoint.x + prePoint.x)*0.5, (curPoint.y + prePoint.y)*0.5};
    
    CGPoint start = self.lastPoint;
    CGPoint control = prePoint;
    CGPoint end = midPoint;
//    NSLog(@"prePoint = %@, curPoint = %@, midPoint = %@", @(prePoint), @(curPoint), @(midPoint));
//    NSLog(@"startPoint = %@", @(startPoint));
    
    CGFloat distance = getTriangleLength(end.x, end.y, start.x, start.y);
    double step = 1.0 / (1 + (int)distance);
    double velocity = MIN(distance * DIS_VEL_CAL_FACTOR, 0.8);
    if (distance == 0) {
        return;
    }
    
    double curVel = distance * DIS_VEL_CAL_FACTOR;
    self.lastVelocity = curVel;
    
    UIColor *lineColor = [UIColor redColor];
    CGFloat lineWidth = self.lastWidth;
    
    double curX = start.x;
    double curY = start.y;
    
    double oldX = start.x;
    double oldY = start.y;
    
    
//    NSLog(@"step = %@, distance = %@, width = %@", @(step), @(distance), @(width));
    NSLog(@"step = %@, velocity = %@", @(step), @(velocity));
    
    BOOL loop = YES;
    float t = 0;
    while (loop) {
        double width = lineWidth * (1 - velocity);
        double curWidth = MAX(width, [UIScreen mainScreen].scale);
        
        if (t < 1) {
            t += step;
            
            //二阶贝塞尔曲线函数取点 pow(x, y)是以x为底y次方
            curX = getPointValue(start.x, end.x, control.x, t);
            curY = getPointValue(start.y, end.y, control.y, t);
            
        } else {
            loop = NO;
        }
        
        if (t == 0) {
            curX = start.x;
            curY = start.y;
        } else if (t == 1) {
            curX = end.x;
            curY = end.y;
        }
        
//        NSLog(@"t = %@, curWidth = %@", @(step), @(curWidth));
        
        [self drawLineWithStart:CGPointMake(oldX, oldY) end:CGPointMake(curX, curY) lineWidth:curWidth lineColor:lineColor];
        
//        NSLog(@"(oldX, oldY) = (%@, %@), width = %@", @(oldX), @(oldY), @(width));
//        NSLog(@"(curX, curY) = (%@, %@), width = %@", @(curX), @(curY), @(width));
        
        oldX = curX;
        oldY = curY;
    }
    
    self.lastPoint = end;
}

- (void)drawLineWithStart:(CGPoint)start end:(CGPoint)end lineWidth:(double)lineWidth lineColor:(UIColor *)lineColor {
    
    double x = start.x;
    double y = start.y;
    
    CALayer *layer = [CALayer layer];
    layer.frame = (CGRect){x, y, lineWidth, lineWidth};
    layer.backgroundColor = lineColor.CGColor;
    layer.masksToBounds = YES;
    layer.cornerRadius = lineWidth;
    [self.layer addSublayer:layer];
}

@end
