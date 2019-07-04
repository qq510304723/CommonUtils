//
//  WDSignatureCanvas.h
//  Uban
//
//  Created by lihuaguang on 2019/7/11.
//  Copyright © 2019 ShineMo Technology Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDSignaturePenConfig.h"

@class WDSignatureCanvas;

NS_ASSUME_NONNULL_BEGIN

@protocol WDSignatureCanvasDelegate <NSObject>

@optional
- (void)canvasViewDidBeganTouch:(WDSignatureCanvas *)canvasView;
- (void)canvasViewDidEndTouch:(WDSignatureCanvas *)canvasView;
- (void)canvasViewDidBacked:(WDSignatureCanvas *)canvasView;

@end

@interface WDSignatureCanvas : UIView

@property (nonatomic, weak) id<WDSignatureCanvasDelegate> delegate;

@property (nonatomic, strong) WDSignaturePenConfig *penConfig;

@property (nonatomic, strong) UIImage *backgroundImage;

@property (nonatomic, copy) NSString *drawImageCachedPath;

- (void)undo;

- (void)eraser;

- (BOOL)canUndo;

//- (UIImage *)drawImage;

- (UIImage *)composedImage;

@end

NS_ASSUME_NONNULL_END
