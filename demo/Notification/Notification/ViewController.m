//
//  ViewController.m
//  Notification
//
//  Created by liufubo on 2020/11/11.
//  Copyright © 2020 watermark. All rights reserved.
//

#import "ViewController.h"
#import "NotificationCenter.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NotificationCenter defaultCenter] addObserver:self selector:@selector(targetAction:) name:@"notificationTargetActionName" object:nil];
    [[NotificationCenter defaultCenter] postNotificationName:@"notificationTargetActionName" object:nil userInfo:@{@"name":@"zhangsan",@"hobby":@"hiking"}];
}

- (void)targetAction:(Notification *)noti {
    NSLog(@"%@,%@",noti.name,noti.userInfo);
}




@end
