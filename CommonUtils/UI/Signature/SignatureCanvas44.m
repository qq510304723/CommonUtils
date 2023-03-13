//
//  WDSignatureCanvas44.m
//  CommonUtils
//
//  Created by lihuaguang on 2019/7/8.
//  Copyright © 2019 lihuaguang. All rights reserved.
//

#import "SignatureCanvas44.h"
#import "SignatureHelper.h"

@implementation SignatureCanvas44 {
    CAShapeLayer *_shapeLayer;
    NSMutableArray *_allPoints;
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

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _allPoints = [NSMutableArray array];
        
        CGPoint start = (CGPoint){100, 100};
        CGPoint end = (CGPoint){200, 200};
        CGPoint control = (CGPoint){200, 100};
        
        CALayer *startLayer = [CALayer layer];
        startLayer.frame = (CGRect){start, 5, 5};
        startLayer.backgroundColor = [UIColor redColor].CGColor;
        [self.layer addSublayer:startLayer];
        
        CALayer *endLayer = [CALayer layer];
        endLayer.frame = (CGRect){end, 5, 5};
        endLayer.backgroundColor = [UIColor greenColor].CGColor;
        [self.layer addSublayer:endLayer];
        
        CALayer *controlLayer = [CALayer layer];
        controlLayer.frame = (CGRect){control, 5, 5};
        controlLayer.backgroundColor = [UIColor blueColor].CGColor;
        [self.layer addSublayer:controlLayer];
        
        CGFloat width = 2;
        CGFloat distance = getTriangleLength(start.x, start.y, end.x, end.y);
        int segements = MAX((int)(distance / width), 2);
        double step = (1.0 / segements);
        
        for (double t = 0; t <= 1; t += step) {
            //二阶贝塞尔曲线函数取点 pow(x, y)是以x为底y次方
            CGFloat x = getPointValue(start.x, end.x, control.x, t);
            CGFloat y = getPointValue(start.y, end.y, control.y, t);
            CGPoint point = CGPointMake(x, y);
            [_allPoints addObject:[NSValue valueWithCGPoint:point]];
        }
        
        NSLog(@"distance = %@, segements= %@, step = %@", @(distance), @(segements), @(step));
        
        [self drawLine];
    }
    return self;
}

- (void)drawLine {
    CGRect frame = CGRectZero;
    frame.size.width = 2;
    frame.size.height = 2;
    
    CGPoint previous = [_allPoints.firstObject CGPointValue];
    for (int i = 1; i < _allPoints.count; i++) {
        CGPoint current = [_allPoints[i] CGPointValue];
        CGPoint mid = (CGPoint){getMidValue(previous.x, current.x), getMidValue(previous.y, current.y)};
        
        frame.origin = previous;
        frame.size.height = fabs(current.y - previous.y);
        
        NSLog(@"frame = %@", @(frame));
        
        UIBezierPath *path1 = [UIBezierPath bezierPathWithOvalInRect:frame];
        CAShapeLayer *layer1 = [self shapeLayer:path1];
        [self.layer addSublayer:layer1];
        
        frame.origin = mid;
        //frame.size.height = fabs(current.y - previous.y);
        
        UIBezierPath *path2 = [UIBezierPath bezierPathWithOvalInRect:frame];
        CAShapeLayer *layer2 = [self shapeLayer:path2];
        [self.layer addSublayer:layer2];
        
        previous = current;
    }
    
    NSLog(@"_allPoints = %@", @(_allPoints.count));
}

- (CAShapeLayer *)shapeLayer:(UIBezierPath *)path {
    CAShapeLayer *layer = [CAShapeLayer layer];
   // layer.strokeColor = [UIColor purpleColor].CGColor;
    layer.fillColor = [UIColor purpleColor].CGColor;
    layer.path = path.CGPath;
    return layer;
}


@end
