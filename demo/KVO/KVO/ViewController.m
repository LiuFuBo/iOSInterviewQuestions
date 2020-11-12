//
//  ViewController.m
//  KVO
//
//  Created by liufubo on 2020/11/11.
//  Copyright © 2020 watermark. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+SKVO.h"
#import "Student.h"

@interface ViewController ()
@property (nonatomic, strong) Student *s1;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _s1 = [[Student alloc]init];
    [_s1 s_addObserver:self keyPath:@"score" options:NSKeyValueObservingOptionNew block:^(NSDictionary *change) {
        NSLog(@"KVO结果:%@",change);
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
      NSLog(@"keyPath=%@ old=%@ new=%@", keyPath, change[NSKeyValueChangeOldKey], change[NSKeyValueChangeNewKey]);
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    static NSInteger num = 0;
    num++;
    _s1.score = @(num);
}

@end
