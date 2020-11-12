//
//  NSObject+SKVO.m
//  KVO
//
//  Created by liufubo on 2020/11/11.
//  Copyright © 2020 watermark. All rights reserved.
//

#import "NSObject+SKVO.h"
#import <objc/message.h>

static const char *SKVO_observer_key = "SKVO_observer_key";
static const char *SKVO_setter_key = "SKVO_setter_key";
static const char *SKVO_getter_key = "SKVO_getter_key";
static const char *SKVO_block_key = "SKVO_block_key";

@implementation NSObject (SKVO)

- (void)s_addObserver:(NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(SKVOBlock)block {
    
    //创建、注册子类
    NSString *oldClassName = NSStringFromClass([self  class]);
    NSString *newClassName = [NSString stringWithFormat:@"SKVONotifying_%@",oldClassName];
    
    Class clazz = objc_getClass(newClassName.UTF8String);
    if (!clazz) {
        clazz = objc_allocateClassPair([self class], newClassName.UTF8String, 0);
        objc_registerClassPair(clazz);
    }
    
    //set方法名
    if (keyPath.length <= 0)return;
    NSString *fChar = [[keyPath substringToIndex:1] uppercaseString];//第一个char
    NSString *rChar = [keyPath substringFromIndex:1];//第二到最后char
    NSString *setterChar = [NSString stringWithFormat:@"set%@%@:",fChar,rChar];
    SEL setSEL = NSSelectorFromString(setterChar);
    
    //添加set方法
    Method getMethod = class_getInstanceMethod([self class], @selector(keyPath));
    const char *types = method_getTypeEncoding(getMethod);
    class_addMethod(clazz, setSEL, (IMP)setterMethod, types);
    
    
    //改变isa指针，指向新建的子类
    object_setClass(self, clazz);
    
    //保存set、get方法名
    objc_setAssociatedObject(self, SKVO_setter_key, setterChar, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, SKVO_getter_key, keyPath, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    //保存observer
    objc_setAssociatedObject(self, SKVO_observer_key, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //保存block
    objc_setAssociatedObject(self, SKVO_block_key, block, OBJC_ASSOCIATION_COPY);
}

void setterMethod(id self, SEL _cmd, id newValue){
    
    //获取set、get犯法名
    NSString *setterChar = objc_getAssociatedObject(self, SKVO_setter_key);
    NSString *getterChar = objc_getAssociatedObject(self, SKVO_getter_key);
    
    //保存子类类型
    Class clazz = [self class];
    
    //isa 指向原类
    object_setClass(self, class_getSuperclass(clazz));
    
    //调用原类get方法，获取oldValue
    id oldValue = objc_msgSend(self, NSSelectorFromString(getterChar));
    
    //调用原类set方法
    objc_msgSend(self, NSSelectorFromString(setterChar),newValue);
    
    NSMutableDictionary *change = [[NSMutableDictionary alloc]init];
    if (newValue) {
        change[NSKeyValueChangeNewKey] = newValue;
    }
    if (oldValue) {
        change[NSKeyValueChangeOldKey] = oldValue;
    }
    
    //原类响应消息更新方法
    NSObject *observer = objc_getAssociatedObject(self, SKVO_observer_key);
    
    objc_msgSend(observer, @selector(observeValueForKeyPath:ofObject:change:context:),getterChar,self,change,nil);
    
    SKVOBlock block = objc_getAssociatedObject(self, SKVO_block_key);
    if (block) {
        block(change);
    }
    
    //isa改回子类类型
    object_setClass(self, clazz);
}


@end
