//
//  NotificationCenter.m
//  Notification
//
//  Created by liufubo on 2020/11/11.
//  Copyright © 2020 watermark. All rights reserved.
//

#import "NotificationCenter.h"

@implementation Notification

+ (instancetype)notificationWithName:(NSString *)aname object:(id)anObject {
    return [Notification notificationWithName:aname object:anObject userInfo:nil];
}

+ (instancetype)notificationWithName:(NSString *)aname object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    
    Notification *nofi = [[Notification alloc]init];
    nofi.name = aname;
    nofi.object = anObject;
    nofi.userInfo = aUserInfo;
    return nofi;
}

- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo {
    return [Notification notificationWithName:name object:object userInfo:userInfo];
}


@end

@implementation NotificationCenter{
    NSMutableArray *_nofiArray;
}

+ (instancetype)defaultCenter {
    static NotificationCenter *_infoCenter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _infoCenter = [[NotificationCenter alloc]init];
    });
    return _infoCenter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _nofiArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)addObserver:(id)observer selector:(SEL)aSelector callBack:(void (^)(void))callBack name:(NSString *)aName object:(id)anObject {
    
    Notification *nofi = [[Notification alloc]init];
    nofi.callBack = callBack;
    nofi.name = aName;
    nofi.aSelector = aSelector;
    nofi.observer = observer;
    [_nofiArray addObject:nofi];
}

- (void)addObserver:(id)observer callBack:(void (^)(void))callBack name:(NSString *)aName object:(id)anObject {
    [self addObserver:observer selector:nil callBack:callBack name:aName object:anObject];
}

- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject {
    [self addObserver:observer selector:aSelector callBack:nil name:aName object:anObject];
}

- (void)postNotificationName:(NSString *)aName object:(id)anObject {
    
    for (Notification *nofi in _nofiArray) {
           if ([nofi.name isEqualToString:aName]) {
               
               nofi.object = anObject ? : anObject;
               
               if (nofi.callBack) {
                   nofi.callBack();
               }
               if (nofi.aSelector) {
                   if ([nofi.observer respondsToSelector:nofi.aSelector]) {
//                       [nofi.observer performSelector:nofi.aSelector withObject:nofi];
                       IMP imp = [nofi.observer methodForSelector:nofi.aSelector];
                       void(*func)(id, SEL,Notification *) = (void *)imp;
                       func(nofi.observer,nofi.aSelector,nofi);
                   }
               }
           }
    }
}

- (void)postNotification:(Notification *)notification {
    for (Notification *nofi in _nofiArray) {
        if ([nofi.name isEqualToString:notification.name]) {
            nofi.callBack = notification.callBack;
            nofi.object = notification.object;
            nofi.aSelector = notification.aSelector;
            nofi.observer = notification.observer;
            nofi.userInfo = notification.userInfo;
            break;
        }
    }
    [self postNotificationName:notification.name object:nil];
}

- (void)postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    
    for (Notification *nofi in _nofiArray) {
        
        if ([nofi.name isEqualToString:aName]) {
            nofi.object = anObject;
            nofi.userInfo = aUserInfo;
            break;
        }
    }
    [self postNotificationName:aName object:nil];
}

@end
