//
//  WDSignatureCanvas.m
//  Uban
//
//  Created by lihuaguang on 2019/7/11.
//  Copyright © 2019 ShineMo Technology Co., Ltd. All rights reserved.
//

#import "WDSignatureCanvas.h"
#import "WDSignatureHelper.h"

#define VEL_MAX 1.2f  // 最大速度
#define VEL_MIN 0.05f  // 最小速度

/**
 二阶贝塞尔曲线函数取点 pow(x, y)是以x为底y次方
 B(t) = (1 - t)^2 * P0 + 2t * (1 - t) * P1 + t^2 * P2, t ∈ [0,1]
 */
static inline CGFloat GetPointValue(CGFloat start, CGFloat end, CGFloat control, float t) {
    return (pow((1 - t), 2) * start + 2 * t * (1 - t) * control + pow(t, 2) * end);
}

static inline CGPoint GetBezierPointForQuadCurve(CGPoint start, CGPoint end, CGPoint control, float t) {
    CGPoint point = CGPointZero;
    point.x = GetPointValue(start.x, end.x, control.x, t);
    point.y = GetPointValue(start.y, end.y, control.y, t);
    return point;
}

// 三角线长度 sqrtf(x^2 + y^2)开平方
static inline CGFloat GetTriangleDistance(CGPoint start, CGPoint end) {
    return sqrtf(pow((start.x - end.x), 2) + pow((start.y - end.y), 2));
}

// 取中间点
static inline CGPoint GetMidPoint(CGPoint start, CGPoint end) {
    CGPoint point = CGPointZero;
    point.x = (start.x + end.x) / 2;
    point.y = (start.y + end.y) / 2;
    return point;
}

// frame不能有小数，不然Eraser时，[canvasImageView.image drawInRect]后，再getImage，大小会变，会出现和self.bounds不相等的情况（没办法解决，只能出此下策）
static inline CGRect GetFixedFrame(CGRect frame) {
    return (CGRect){(int)frame.origin.x, (int)frame.origin.y, (int)frame.size.width, (int)frame.size.height};
}

@interface WDSignatureCanvas ()

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIImageView *canvasImageView;

@property (nonatomic, strong) NSMutableArray *drawImagePathArray;
@property (nonatomic, strong) NSMutableArray *drawLineLayerArray;

@property (nonatomic, strong) UIBezierPath *eraserBezierPath;

@property (nonatomic, assign) CGPoint lastPoint;
@property (nonatomic, assign) CGFloat lastVel;

@end

@implementation WDSignatureCanvas
@synthesize drawImageCachedPath = _drawImageCachedPath;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:GetFixedFrame(frame)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.bgImageView = [[UIImageView alloc] init];
        self.bgImageView.frame = self.bounds;
        [self addSubview:self.bgImageView];
        
        self.canvasImageView = [[UIImageView alloc] init];
        self.canvasImageView.frame = self.bgImageView.bounds;
        [self addSubview:self.canvasImageView];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    CGRect realFrame = GetFixedFrame(frame);
    [super setFrame:realFrame];
    
    self.bgImageView.frame = self.bounds;
    self.canvasImageView.frame = self.bounds;
}

- (void)setBackgroundImage:(UIImage *)image {
    _backgroundImage = image;
    self.bgImageView.image = image;
}

- (void)setDrawImageCachedPath:(NSString *)cachedPath {
    _drawImageCachedPath = cachedPath.copy;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [WDSignatureHelper ensureDirExistAtPath:cachedPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *picPaths = [fileManager contentsOfDirectoryAtPath:cachedPath error:nil];
        
        [picPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *picPath = [self.drawImageCachedPath stringByAppendingPathComponent:obj];
            if (picPath.length) {
                [self.drawImagePathArray addObject:picPath];
            }
        }];
        
        NSString *picPath = [self.drawImagePathArray lastObject];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:picPath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.canvasImageView.image = image;
        });
    });
}

- (void)undo {
    if (![self canUndo]) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *picPath = [self.drawImagePathArray lastObject];
        [WDSignatureHelper removeFile:picPath];
        [self.drawImagePathArray removeLastObject];
        
        picPath = [self.drawImagePathArray lastObject];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:picPath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.canvasImageView.image = image;
        });
    });
    
    if ([self.delegate respondsToSelector:@selector(canvasViewDidBacked:)]) {
        [self.delegate canvasViewDidBacked:self];
    }
}

- (void)eraser {
    if (![self canUndo]) {
        return;
    }
    
    [self.drawImagePathArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [WDSignatureHelper removeFile:obj];
    }];
    [self.drawImagePathArray removeAllObjects];
    self.canvasImageView.image = nil;
    
    if ([self.delegate respondsToSelector:@selector(canvasViewDidBacked:)]) {
        [self.delegate canvasViewDidBacked:self];
    }
}

- (BOOL)canUndo {
    return (self.drawImagePathArray.count > 0);
}

- (UIImage *)drawImage {
    return self.canvasImageView.image;
}

- (UIImage *)composedImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.layer renderInContext:context];
    
    UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return getImage;
}

#pragma mark - Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (![self checkEnableTouch]) {
        return;
    }
    
    UITouch *touch = (UITouch *)[touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    self.lastPoint = currentPoint;
    self.lastVel = VEL_MIN;
    
    if (self.penConfig.isEraser) {
        self.eraserBezierPath = [UIBezierPath bezierPath];
        [self.eraserBezierPath moveToPoint:currentPoint];
        self.eraserBezierPath.lineWidth = 20;
    } else {
        
    }
    
    if ([self.delegate respondsToSelector:@selector(canvasViewDidBeganTouch:)]) {
        [self.delegate canvasViewDidBeganTouch:self];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (![self checkEnableTouch]) {
        return;
    }
    
    UITouch *touch = (UITouch *)[touches anyObject];
    if (self.penConfig.isEraser) {;
        [self eraserWithTouch:touch];
    } else {
        [self drawLineWithTouch:touch];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (![self checkEnableTouch]) {
        return;
    }
    
    //保存到存储，撤销用
    [self saveDrawImage];

    if (self.drawLineLayerArray.count) {
        [self.drawLineLayerArray enumerateObjectsUsingBlock:^(CALayer * _Nonnull layer, NSUInteger idx, BOOL * _Nonnull stop) {
            [layer removeFromSuperlayer];
        }];
        [self.drawLineLayerArray removeAllObjects];
    }
    
    if ([self.delegate respondsToSelector:@selector(canvasViewDidEndTouch:)]) {
        [self.delegate canvasViewDidEndTouch:self];
    }
}

- (BOOL)checkEnableTouch {
    // 橡皮擦模式，没有轨迹了直接返回
    if (![self canUndo] && self.penConfig.isEraser) {
        return NO;
    }
    return YES;
}

- (void)drawLineWithTouch:(UITouch *)touch {
    /* 根据 touch 获取坐标 */
    CGPoint currentLocation = [touch locationInView:self];
    CGPoint previousLocation = [touch previousLocationInView:self];
    CGPoint midLocation = GetMidPoint(currentLocation, previousLocation);
    
    CGPoint start = self.lastPoint;
    CGPoint control = previousLocation;
    CGPoint end = midLocation;
    
    /* 计算距离和速度 */
    CGFloat distance = GetTriangleDistance(start, end);
    if (distance <= 0) {
        return;
    }
    
    double curVel = distance * 0.02;
    curVel = MAX(VEL_MIN, curVel);
    curVel = MIN(VEL_MAX, curVel);
    
    // 点距设定到大于笔迹的尺寸，可以画出类似虚线的效果
    CGFloat lineWidth = 2.0;   // 笔迹的尺寸
    CGFloat pointDis = lineWidth / 2;               // 点距
    
    int segements = MAX((int)(distance / pointDis), 2);
    double step = (1.0 / segements);
    
    
#if DEBUG
    NSLog(@"\n\n==========");
//    NSLog(@"distance = %.3f", distance);
    NSLog(@"distance = %.3f, segements = %d, step = %.3f", distance, segements, step);
#endif
    
    /* 根据二次贝塞尔曲线算法取点 */
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:start];
    CGPoint old = start;
    for (double t = 0; t <= 1; t += step) {
        CGPoint current = GetBezierPointForQuadCurve(start, end, control, t);
        CGPoint mid = (CGPoint){(current.x + old.x)*0.5, (current.y + old.y)*0.5};

        CGFloat calVel = self.lastVel + (curVel - self.lastVel) * t;
        CGFloat size = lineWidth * (VEL_MAX - calVel);
        size = MAX(size, 0.1);
//        NSLog(@"lastVel = %.3f, curVel = %.3f, calVel = %.3f, size = %.3f, t = %.3f", self.lastVel, curVel, calVel, size, t);

#if DEBUG
//        NSLog(@"curWidth = %.3f, lastWidth = %.3f, curVel = %.3f, lastVel = %.3f", curWidth, curWidth, curVel, self.lastVel);
//        NSLog(@"force = %.3f, lastForce = %.3f, curForce = %.3f, size = %.3f", self.lastForce, force, curForce, size);
#endif

        CGRect frame = (CGRect){old, size, size};
        UIBezierPath *path1 = [UIBezierPath bezierPathWithOvalInRect:frame];
        [bezierPath appendPath:path1];

        frame = (CGRect){mid, size, size};
        UIBezierPath *path2 = [UIBezierPath bezierPathWithOvalInRect:frame];
        [bezierPath appendPath:path2];

        old = current;
    }
//    [bezierPath addQuadCurveToPoint:end controlPoint:control];
//    old = end;
    
    
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
//    shapeLayer.lineWidth = force * lineWidth;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.strokeColor = self.penConfig.lineColor.CGColor;
    shapeLayer.path = bezierPath.CGPath;
    [self.canvasImageView.layer addSublayer:shapeLayer];
    [self.drawLineLayerArray addObject:shapeLayer];
    
    self.lastPoint = old;
    self.lastVel = curVel;
}

- (void)eraserWithTouch:(UITouch *)touch {
    CGPoint currentPoint = [touch locationInView:self];
    [self.eraserBezierPath addLineToPoint:currentPoint];
    
    // 绘图
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    [self.canvasImageView.image drawInRect:self.bounds];
    [[UIColor clearColor] set];
    
    [self.eraserBezierPath strokeWithBlendMode:kCGBlendModeClear alpha:1.0];
    [self.eraserBezierPath stroke];
    
    UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
    self.canvasImageView.image = getImage;
    
    UIGraphicsEndImageContext();
}

- (UIImage *)imageForCanvas {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.canvasImageView.layer renderInContext:context];
    
    UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.canvasImageView.image = getImage;
    
    return getImage;
}

- (void)saveDrawImage {
    UIImage *image = [self imageForCanvas];
    if (!image) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDate *date = [NSDate date];
        NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
        [dateformatter setDateFormat:@"yyyyMMdd-HHmmssSSS"];
        NSString *now = [dateformatter stringFromDate:date];
        NSString *picPath = [self.drawImageCachedPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", now]];
        NSData *imgData = UIImagePNGRepresentation(image);
        BOOL success = [imgData writeToFile:picPath atomically:YES];
        if (success) {
            [self.drawImagePathArray addObject:picPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.canvasImageView.image = image;
            });
        } else {
            NSLog(@"save canvas image error");
        }
    });
}

#pragma mark - Getters

- (WDSignaturePenConfig *)penConfig {
    if (!_penConfig) {
        _penConfig = [[WDSignaturePenConfig alloc] init];
        _penConfig.lineWidth = 2;
        _penConfig.lineColor = [UIColor redColor];
        _penConfig.isEraser = NO;
    }
    return _penConfig;
}

- (NSMutableArray *)drawImagePathArray {
    if (!_drawImagePathArray) {
        _drawImagePathArray = [NSMutableArray array];
    }
    return _drawImagePathArray;
}

- (NSMutableArray *)drawLineLayerArray {
    if (!_drawLineLayerArray) {
        _drawLineLayerArray = [NSMutableArray array];
    }
    return _drawLineLayerArray;
}

- (NSString *)drawImageCachedPath {
    if (!_drawImageCachedPath) {
        _drawImageCachedPath = NSTemporaryDirectory();
    }
    return _drawImageCachedPath;
}

@end
