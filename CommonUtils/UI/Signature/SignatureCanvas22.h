//
//  WDSignatureCanvas22.h
//  CommonUtils
//
//  Created by lihuaguang on 2019/6/28.
//  Copyright © 2019 lihuaguang. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SignatureCanvas22 : UIView

- (instancetype)initWithFrame:(CGRect)frame;

// 撤销
- (void)undo;
- (BOOL)canUnDo;

// 清空
- (void)eraser;

@end

NS_ASSUME_NONNULL_END
