//
//  NotificationCenter.h
//  Notification
//
//  Created by liufubo on 2020/11/11.
//  Copyright © 2020 watermark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Notification : NSObject
@property (nonatomic, strong, readwrite) NSDictionary *userInfo;
@property (nonatomic, assign) id object;
@property (nonatomic, assign) id observer;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) void(^callBack)(void);
@property (nonatomic, assign) SEL aSelector;

- (NSString *)name;
- (id)object;
- (NSDictionary *)userInfo;

+ (instancetype)notificationWithName:(NSString *)aname object:(id)anObject;
+ (instancetype)notificationWithName:(NSString *)aname object:(id)anObject userInfo:(NSDictionary *)aUserInfo;
- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo;


@end


@interface NotificationCenter : NSObject

+ (instancetype)defaultCenter;
- (void)addObserver:(id)observer callBack:(void(^)(void))callBack name:(NSString *)aName object:(id)anObject;
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject;

- (void)postNotification:(Notification *)notification;
- (void)postNotificationName:(NSString *)aName object:(id)anObject;
- (void)postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;

@end


