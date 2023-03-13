//
//  WDSignaturePenConfig.h
//  Uban
//
//  Created by lihuaguang on 2019/7/9.
//  Copyright © 2019 ShineMo Technology Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SignaturePenConfig : NSObject

//画笔颜色
@property (nonatomic, strong) UIColor *lineColor;

//画笔宽度
@property (nonatomic, assign) CGFloat lineWidth;

//是否是橡皮擦
@property (nonatomic, assign) BOOL isEraser;

@end

NS_ASSUME_NONNULL_END
