//
//  WDSignatureHelper.m
//  CommonUtils
//
//  Created by lihuaguang on 2019/7/8.
//  Copyright © 2019 lihuaguang. All rights reserved.
//

#import "WDSignatureHelper.h"

// 二阶贝塞尔曲线函数取点 pow(x, y)是以x为底y次方
double getPointValue(double start, double end, double control, double t) {
    return (pow((1 - t), 2) * start + 2 * t * (1 - t) * control + pow(t, 2) * end);
}

// 三角线长度 sqrtf(x^2 + y^2)开平方
double getTriangleLength(double x1, double y1, double x2, double y2) {
    return sqrtf((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
}

double getTriangleCoord(double x1, double y1, double x2, double y2) {
    return sqrtf((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
}

double getMidValue(double x1, double x2) {
    return (x1 + x2) / 2;
}

@implementation WDSignatureHelper

+ (void)ensureDirExistAtPath:(NSString *)dirPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = false;
    BOOL exists = [fm fileExistsAtPath:dirPath isDirectory:&isDir];
    if (exists) {
        if (!isDir) {
            [fm removeItemAtPath:dirPath error:nil];
            [fm createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    } else {
        [fm createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (BOOL)removeFile:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    return success;
}

@end
