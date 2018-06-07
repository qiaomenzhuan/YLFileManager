//
//  ViewController.m
//  YLFileManager
//
//  Created by 杨磊 on 2018/6/7.
//  Copyright © 2018年 csda_Chinadance. All rights reserved.
//

#import "ViewController.h"
#import "YLFileManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    YLFileManager *manger = [[YLFileManager alloc] init];
    manger.fid = @"gg";
    [manger exportFile:^(NSString *result) {
        NSLog(@"%@",result);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
