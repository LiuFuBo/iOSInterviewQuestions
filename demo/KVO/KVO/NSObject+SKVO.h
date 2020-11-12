//
//  NSObject+SKVO.h
//  KVO
//
//  Created by liufubo on 2020/11/11.
//  Copyright © 2020 watermark. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SKVOBlock)(NSDictionary *change);

@interface NSObject (SKVO)

- (void)s_addObserver:(NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(SKVOBlock)block;

@end


