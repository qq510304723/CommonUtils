//
//  ViewController.m
//  CommonUtils
//
//  Created by lihuaguang on 2019/5/20.
//  Copyright © 2019 lihuaguang. All rights reserved.
//

#import "ViewController.h"
#import "WDSignatureCanvas.h"
#import "WDSignatureCanvas22.h"
#import "WDSignatureCanvas33.h"
#import "WDSignatureCanvas44.h"

@interface ViewController ()

@property (nonatomic, strong) WDSignatureCanvas *canvasView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGRect frame = (CGRect){20, 100, self.view.bounds.size.width - 40, 500};
    
    self.canvasView = [[WDSignatureCanvas alloc] initWithFrame:frame];
    self.canvasView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.canvasView];

    UIButton *eraser = [UIButton buttonWithType:UIButtonTypeSystem];
    [eraser setTitle:@"eraser" forState:UIControlStateNormal];
    [eraser addTarget:self action:@selector(eraser) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:eraser];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
    [back setTitle:@"back" forState:UIControlStateNormal];
    [back addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];

    eraser.frame = CGRectMake(30, 620, 50, 30);
    back.frame = CGRectMake(100, 620, 50, 30);
}

- (void)back {
    [self.canvasView undo];
}

- (void)eraser {
    [self.canvasView eraser];
}

@end
