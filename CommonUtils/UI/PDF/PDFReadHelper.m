//
//  PDFReadHelper.m
//  Uban
//
//  Created by lihuaguang on 2019/5/24.
//  Copyright © 2019 ShineMo Technology Co., Ltd. All rights reserved.
//

#import "PDFReadHelper.h"
#import <CoreGraphics/CoreGraphics.h>

@interface PDFReadHelper ()

@end

@implementation PDFReadHelper

+ (NSArray *)readAllPdfImages:(NSString *)filePath {
    if (filePath.length == 0) {
        return nil;
    }
    
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    CFURLRef refURL = (__bridge_retained CFURLRef)fileUrl;
    CGPDFDocumentRef documentRef = CGPDFDocumentCreateWithURL(refURL);
    size_t totalPage = CGPDFDocumentGetNumberOfPages(documentRef);
    CFRelease(refURL);
    
    NSMutableArray *resultImages = [NSMutableArray array];
    for (int i = 1; i < totalPage; i++) {
        UIImage *image = [self drawingPdfImageWithPdfRef:documentRef pageIndex:i];
        [resultImages addObject:image];
    }
    CGPDFDocumentRelease(documentRef);
    
    return resultImages;
}

+ (UIImage *)drawingPdfImageWithPdfRef:(CGPDFDocumentRef)documentRef pageIndex:(int)pageIndex {
    // 获取pdf当前页内容和大小
    CGPDFPageRef pageRef = CGPDFDocumentGetPage(documentRef, pageIndex);
    CGRect rect = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 填充背景色，否则为全黑色
    [[UIColor whiteColor] set];
    CGContextFillRect(context, rect);
    
    // 设置位移，x，y
    CGContextTranslateCTM(context, 0, rect.size.height);
    
    // Quartz坐标系和UIView坐标系不一样所致，调整坐标系，使pdf正立
    CGContextScaleCTM(context, 1, -1);
    
    // 绘制pdf
    CGContextDrawPDFPage(context, pageRef);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
