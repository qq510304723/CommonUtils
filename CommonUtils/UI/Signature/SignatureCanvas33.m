//
//  WDSignatureCanvas33.m
//  CommonUtils
//
//  Created by lihuaguang on 2019/7/8.
//  Copyright © 2019 lihuaguang. All rights reserved.
//

#import "SignatureCanvas33.h"
#import "SignatureHelper.h"

// 点距设定到大于笔迹的尺寸，甚至可以画出类似虚线的效果
#define LINE_POINT_SIZE 3.0f  // 笔迹的尺寸
#define LINE_POINT_DIS 2.0f  // 点距

@interface SignatureCanvas33 ()

@property (nonatomic, assign) CGPoint lastPoint;
@property (nonatomic, assign) CGFloat lastForce;
@property (nonatomic, strong) NSMutableArray *allPoints;

@end

@implementation SignatureCanvas33

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
    }
    return self;
}

// 撤销
- (void)undo {
    
}
- (BOOL)canUnDo {
    return YES;
}

// 清空
- (void)eraser {
    NSArray *layers = [self.layer.sublayers copy];
    for (CALayer *layer in layers) {
        [layer removeFromSuperlayer];
    }
}

#pragma mark - Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = (UITouch *)[touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    
//    CALayer *layer = [CALayer layer];
//    layer.frame = (CGRect){currentPoint, 5, 5};
//    layer.backgroundColor = [UIColor redColor].CGColor;
//    [self.layer addSublayer:layer];
    
    _allPoints = [NSMutableArray array];
    self.lastPoint = currentPoint;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = (UITouch *)[touches anyObject];
//    CGPoint currentPoint = [touch locationInView:self];
//
//    CALayer *layer = [CALayer layer];
//    layer.frame = (CGRect){currentPoint, 5, 5};
//    layer.backgroundColor = [UIColor greenColor].CGColor;
//    [self.layer addSublayer:layer];
    
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
    
    CGFloat force = touch.force;
    if (force == 0) {
        force = 1.0;
    }
    if (force < 0.3) {
        force = 0.3;
    }
    if (force > 2) {
        force = 2;
    }
    
    CGFloat factor = LINE_POINT_DIS;
    if (force <= 1) {
        factor = LINE_POINT_DIS * force;
    }
    CGFloat distance = getTriangleLength(start.x, start.y, end.x, end.y);
    int segements = MAX((int)(distance / factor), 2);
    double step = (1.0 / segements);
    
    NSMutableArray *points = [NSMutableArray array];
    for (double t = 0; t <= 1; t += step) {
        //二阶贝塞尔曲线函数取点 pow(x, y)是以x为底y次方
        CGFloat x = getPointValue(start.x, end.x, control.x, t);
        CGFloat y = getPointValue(start.y, end.y, control.y, t);
        CGPoint point = CGPointMake(x, y);
        [_allPoints addObject:[NSValue valueWithCGPoint:point]];
        [points addObject:[NSValue valueWithCGPoint:point]];
    }
    [points addObject:[NSValue valueWithCGPoint:end]];
    
   // NSLog(@"distance = %@, segements= %@, step = %@", @(distance), @(segements), @(step));
  //  NSLog(@"force = %@, factor = %@", @(force), @(factor));
    
    [self drawLineWithPoints:points force:force];
    
}

- (void)drawLineWithPoints:(NSArray *)points force:(CGFloat)force {
    
    CGFloat step = (force - self.lastForce) / points.count;
 //   NSLog(@"step = %@", @(step));
    
    CGPoint previous = [points.firstObject CGPointValue];
    for (int i = 1; i < points.count; i++) {
        
        CGFloat curForce = self.lastForce + step * i;
      //  NSLog(@"===== lastForce = %@, force = %@, curForce = %@", @(self.lastForce), @(force), @(curForce));
        
        CGFloat size = LINE_POINT_SIZE * curForce;
        
        CGPoint current = [points[i] CGPointValue];
        CGPoint mid = (CGPoint){getMidValue(previous.x, current.x), getMidValue(previous.y, current.y)};

        
        CGRect frame = (CGRect){previous, size, size};
        UIBezierPath *path1 = [UIBezierPath bezierPathWithOvalInRect:frame];
        CAShapeLayer *layer1 = [self shapeLayer:path1];
        [self.layer addSublayer:layer1];
        
        frame = (CGRect){mid, size, size};
        UIBezierPath *path2 = [UIBezierPath bezierPathWithOvalInRect:frame];
        CAShapeLayer *layer2 = [self shapeLayer:path2];
        [self.layer addSublayer:layer2];
        
        previous = current;
    }
    
    self.lastPoint = previous;
    self.lastForce = force;
}

- (CAShapeLayer *)shapeLayer:(UIBezierPath *)path {
    CAShapeLayer *layer = [CAShapeLayer layer];
//    layer.strokeColor = [UIColor purpleColor].CGColor;
    layer.fillColor = [UIColor purpleColor].CGColor;
    layer.path = path.CGPath;
    return layer;
}

@end
