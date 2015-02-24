//
//  NSObject+MMAnonymousClass.m
//  Runtime
//
//  Created by flanker on 21.02.13.
//  Copyright (c) 2013 LOL. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "NSObject+MMAnonymousClass.h"

NSString *const kMMExeptionMethodError = @"MMExeptionMethodError";
NSString *const kMMExeptionSelector = @"MMExeptionSelector";

Class MM_CREATE_CLASS(NSString *reuseID, Class superclass, void(^block)(__strong Class class))
{
    return [superclass subclassWithReuseID:reuseID configBlock:block];
}

Class MM_CREATE_CLASS_ALWAYS(Class superclass, void(^block)(__strong Class class))
{
    return [superclass subclassWithReuseID:nil configBlock:block];
}

id MM_CREATE(NSString *reuseID, void(^block)(__strong Class class))
{
    Class class = MM_CREATE_CLASS(reuseID, [NSObject class], block);
    return [[class alloc] init];
}

id MM_CREATE_ALWAYS(void(^block)(__strong Class class))
{
    Class class = MM_CREATE_CLASS_ALWAYS([NSObject class], block);
    return [[class alloc] init];
}

@implementation NSObject (MMAnonymousClass)

+ (Class)subclassWithReuseID:(NSString *)reuseID
                 configBlock:(void(^)(Class class))block
{
    reuseID = [[reuseID componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
    BOOL nilReuseID = (reuseID == nil);
    if (reuseID == nil) {
        static NSInteger index = 0;
        reuseID = [NSString stringWithFormat:@"MMAnonymousClass%@",@(index++)];
    }
    
    Class ret = NSClassFromString(reuseID);
    if (ret == nil) {
        ret = objc_allocateClassPair([self class], reuseID.UTF8String, 0);
        block(ret);
        if (nilReuseID) {
            SEL sel = NSSelectorFromString(@"dealloc");
            IMP imp = class_getMethodImplementation(self, sel);
            IMP newImp = imp_implementationWithBlock(^(id this) {
                [ret deleteClass];
            });
            [ret overrideMethod:sel blockImp:^(id this){
                ((void(*)(id))newImp)(this);
                ((void(*)(id))imp)(this);
            }];
        }
        objc_registerClassPair(ret);
    }
    
    return ret;
}

+ (void)addMethod:(SEL)sel fromProtocol:(Protocol *)proto blockImp:(id)block {
    struct objc_method_description descript = protocol_getMethodDescription(proto, sel, NO, YES);
    if (descript.types == nil)
        descript = protocol_getMethodDescription(proto, sel, YES, YES);
    if (descript.types) {
        [self addMethod:sel blockImp:block types:descript.types];
        return;
    }
    
    NSString *reason = [NSString stringWithFormat:@"Method (%@) can't be found. Please, check %@ protocol",NSStringFromSelector(sel),NSStringFromProtocol(proto)];
    @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
}

+ (void)addMethod:(SEL)sel fromClass:(Class)class blockImp:(id)block {
    Method method = class_getInstanceMethod(class, sel);
    if (method) {
        const char *types = method_getTypeEncoding(method);
        [self addMethod:sel blockImp:block types:types];
        return;
    }
    
    NSString *reason = [NSString stringWithFormat:@"Method (%@) can't be found. Please, check %@ class",NSStringFromSelector(sel),NSStringFromClass(class)];
    @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
}

+ (void)addMethod:(SEL)sel blockImp:(id)block types:(const char *)types {
    IMP newImp = imp_implementationWithBlock(block);
    class_replaceMethod(self, sel, newImp, types);
}

+ (void)overrideMethod:(SEL)sel blockImp:(id)block {
    Method method = class_getInstanceMethod(self, sel);
    if (method) {
        class_replaceMethod(self, sel, imp_implementationWithBlock(block), method_getTypeEncoding(method));
        return;
    }
    
    NSString *reason = [NSString stringWithFormat:@"Method (%@) can't be overriden. It does not exists",NSStringFromSelector(sel)];
    @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
}

+ (void)removeMethod:(SEL)sel
{
    Method method = class_getInstanceMethod(self, sel);
    if (method != nil) {
        method_setImplementation(method,(IMP)_objc_msgForward);
        return;
    }
    
    NSString *reason = [NSString stringWithFormat: @"Method (%@) can't be removed. Method not found",NSStringFromSelector(sel)];
    @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
}

+ (void)removeClassMethod:(SEL)sel
{
    Method method = class_getClassMethod(self, sel);
    if (method != nil) {
        method_setImplementation(method,(IMP)_objc_msgForward);
        return;
    }
    
    NSString *reason = [NSString stringWithFormat: @"Method (%@) can't be removed. Method not found",NSStringFromSelector(sel)];
    @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
}

+ (void)deleteClass
{
    dispatch_async(dispatch_get_main_queue(), ^{
        objc_disposeClassPair(self);
    });
}

@end
