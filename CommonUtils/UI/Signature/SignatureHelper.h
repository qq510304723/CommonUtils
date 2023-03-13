//
//  WDSignatureHelper.h
//  CommonUtils
//
//  Created by lihuaguang on 2019/7/8.
//  Copyright © 2019 lihuaguang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 二阶贝塞尔曲线函数取点 pow(x, y)是以x为底y次方
double getPointValue(double start, double end, double control, double t);

// 三角线长度 sqrtf(x^2 + y^2)开平方
double getTriangleLength(double x1, double y1, double x2, double y2);

double getTriangleCoord(double x1, double y1, double x2, double y2);

double getMidValue(double x1, double x2);

@interface SignatureHelper : NSObject

+ (void)ensureDirExistAtPath:(NSString *)dirPath;

+ (BOOL)removeFile:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
