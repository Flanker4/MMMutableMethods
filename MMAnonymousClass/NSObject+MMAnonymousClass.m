//
//  NSObject+MMAnonymousClass.m
//  Runtime
//
//  Created by flanker on 21.02.13.
//  Copyright (c) 2013 LOL. All rights reserved.
//

#import "NSObject+MMAnonymousClass.h"
#import <objc/runtime.h>


NSString *const kMMExeptionMethodError          = @"MMExeptionMethodError";
NSString *const kMMExeptionSelector             = @"MMExeptionSelector";

static Class newClass=nil;
static bool  mm_error_flag=NO;
BOOL OVERRIDE(SEL sel,id blockIMP){
    BOOL result=NO;
    if (newClass) {
        Method method = class_getInstanceMethod(newClass, sel);
        if (method) {
            class_replaceMethod(newClass, sel, imp_implementationWithBlock(blockIMP), method_getTypeEncoding(method));
            result=YES;
        }
    }
    if (result==NO) {
        //method can't be overrided. Please, check params
        mm_error_flag=YES;
        NSString *reason=[NSString stringWithFormat:@"Method (%@) can't be overrided. Please, check params",NSStringFromSelector(sel)];
        @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
    }
    return result;
}
BOOL ADD_METHOD(SEL sel,Protocol *p, BOOL isReq, id blockIMP){
    BOOL result=NO;
    if (newClass) {
        Method method = class_getInstanceMethod(newClass, sel);
        if (method) {
            result = OVERRIDE(sel, blockIMP);
        }else{
            struct objc_method_description descript=protocol_getMethodDescription(p, sel, isReq, YES);
            if (descript.types!=NULL) {
                IMP newImp = imp_implementationWithBlock(blockIMP);
                result=class_addMethod(newClass, sel, newImp, descript.types);
            }
        }
    }
    if (result==NO) {
        //method can't be added. Please, check params
        mm_error_flag=YES;
        NSString *reason=[NSString stringWithFormat:@"Method (%@) can't be added. Please, check params",NSStringFromSelector(sel)];
        @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
    }
    return result;

}
BOOL  ADD_METHOD_C(SEL sel,Class c,id blockIMP){
    BOOL result=NO;
    if (newClass) {
        Method method = class_getInstanceMethod(newClass, sel);
        if (method) {
            result = OVERRIDE(sel, blockIMP);
        }else{
            method = class_getInstanceMethod(c, sel);
            if (method) {
                IMP newImp = imp_implementationWithBlock(blockIMP);
                result=class_addMethod(newClass, sel, newImp, method_getTypeEncoding(method));
            }
        }
        
    }
    if (result==NO) {
        //method can't be added. Please, check params
        NSString *reason=[NSString stringWithFormat:@"Method (%@) can't be added. Please, check params",NSStringFromSelector(sel)];
        @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
    }
    return result;

}

@implementation NSObject (MMAnonymousClass)

-(id) modifyMethods:(void(^)())ovBlock{
    //universal mutex ?????
    @synchronized([NSObject class]){
        //Частично использован код Sergey Starukhin
        //из форка см.
        //https://github.com/pingvin4eg/MMMutableMethods/blob/master/MMMutableMethod/NSObject%2BOverrideMethod.m
        
        newClass=nil;
        NSString *objClassStr= NSStringFromClass([self class]);
        NSString *format=@"%@_anon_%i";
        NSUInteger i=0;
        
        NSString *newClassStr =nil;
        do{
            newClassStr = [NSString stringWithFormat:format,objClassStr,i];
            newClass = NSClassFromString(newClassStr);
            i++;
        }while(newClass);
        
        newClass = objc_allocateClassPair([self class], [newClassStr UTF8String], 0);
        mm_error_flag=NO;
        ovBlock();
        if (mm_error_flag){
            return nil;
        }
        objc_registerClassPair(newClass);
        object_setClass(self, newClass);
        return self;
    }
}
-(id) addMethod:(SEL)sel fromProtocol:(Protocol *)p isRequired:(BOOL)isReq blockImp:(id)block{
    return [self modifyMethods:^{
        ADD_METHOD(sel, p, isReq, block);
    }];
}
-(id) overrideMethod:(SEL)sel blockImp:(id)block{
    return [self modifyMethods:^{
        OVERRIDE(sel,  block);
    }];
}
+ (id)new:(void(^)())blockOv{
    return  [[[self class] alloc] init:blockOv];
}
- (id)init:(void(^)())blockOv{
    id obj=[self init];
    return [obj modifyMethods:blockOv];
}
@end