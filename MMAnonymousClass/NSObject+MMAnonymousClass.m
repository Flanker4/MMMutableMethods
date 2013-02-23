//
//  NSObject+MMAnonymousClass.m
//  Runtime
//
//  Created by flanker on 21.02.13.
//  Copyright (c) 2013 LOL. All rights reserved.
//

#import "NSObject+MMAnonymousClass.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString *const kMMExeptionMethodError          = @"MMExeptionMethodError";
NSString *const kMMExeptionSelector             = @"MMExeptionSelector";

static Class newClass=nil;
static bool  mm_error_flag=NO;

 inline BOOL OVERRIDE     (SEL sel,id blockIMP){
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
 static inline BOOL ADD_METHOD_IN(SEL sel,const char *types, id blockIMP){
    BOOL result=NO;
    if ((newClass)&&(types)) {
        Method method = class_getInstanceMethod(newClass, sel);
        if (method) {
            result = OVERRIDE(sel, blockIMP);
        }else{
            IMP newImp = imp_implementationWithBlock(blockIMP);
            result=class_addMethod(newClass, sel, newImp, types);
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
 inline BOOL ADD_METHOD   (SEL sel,Protocol *p, BOOL isReq, id blockIMP){
    struct objc_method_description descript=protocol_getMethodDescription(p, sel, isReq, YES);
    return ADD_METHOD_IN(sel, descript.types, blockIMP);
}
 inline BOOL ADD_METHOD_C (SEL sel,Class c, id blockIMP){
    Method method = class_getInstanceMethod(c, sel);
    return ADD_METHOD_IN(sel, method_getTypeEncoding(method), blockIMP);
}


@implementation NSObject (MMAnonymousClass)


+(Class) anonClass:(void(^)())blockOv{
    //universal mutex ?????
    @synchronized([NSObject class]){
        //использован код Sergey Starukhin
        //из форка см. https://github.com/pingvin4eg/MMMutableMethods
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
        if (!newClass){
            return newClass;
        }
        mm_error_flag=NO;
        blockOv();
        if (mm_error_flag){
            return NULL;
        }
        objc_registerClassPair(newClass);
        return newClass;
    }

}

//
// MARK: - Primary
//
+ (id)allocAnonClass:(void(^)())blockOv{
    Class newClass=[self anonClass:blockOv];
    id inst =[newClass alloc];
    newClass =nil;
    return inst;
}
+ (id)newInstAnonClass:(void(^)())blockOv{
    return  [[[self class] allocAnonClass:blockOv] init];
}

//
// MARK: - Deprecated!
//
-(id) modifyMethods:(void(^)())blockOv{
    Class newClass=[[self class] anonClass:blockOv];
    object_setClass(self, newClass);
    return self;
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
@end
