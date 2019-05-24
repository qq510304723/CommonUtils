//
//  PDFReadHelper.h
//  Uban
//
//  Created by lihuaguang on 2019/5/24.
//  Copyright © 2019 ShineMo Technology Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PDFReadHelper : NSObject

+ (NSArray *)readAllPdfImages:(NSString *)filePath;

@end
