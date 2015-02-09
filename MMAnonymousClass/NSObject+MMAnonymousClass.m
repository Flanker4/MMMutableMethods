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
 inline BOOL ADD_METHOD   (SEL sel,Protocol *p, id blockIMP){
    struct objc_method_description descript=protocol_getMethodDescription(p, sel, NO, YES);
    if (!descript.types) {
         descript=protocol_getMethodDescription(p, sel, YES, YES);
    }
    return ADD_METHOD_IN(sel, descript.types, blockIMP);
}
 inline BOOL ADD_METHOD_C (SEL sel,Class c, id blockIMP){
    Method method = class_getInstanceMethod(c, sel);
    return ADD_METHOD_IN(sel, method_getTypeEncoding(method), blockIMP);
}


@implementation NSObject (MMAnonymousClass)


+(Class) anonClass:(void(^)())blockOv reuseID:(NSString*)reuseID{
    //universal mutex ?????
    @synchronized([NSObject class]){
        
        //частично использован код Sergey Starukhin
        //из форка см. https://github.com/pingvin4eg/MMMutableMethods
        newClass=nil;
        NSString *objClassStr= NSStringFromClass([self class]);
        NSString *FORMAT=@"%@_anon_%@";
        NSString *newClassStr =nil;
        if (reuseID) {
            reuseID = [[reuseID componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
            newClassStr = [NSString stringWithFormat:FORMAT,objClassStr,reuseID];
            newClass = NSClassFromString(newClassStr);
            if (newClass) {
                mm_error_flag=NO;
                blockOv();
                if (mm_error_flag){
/*->*/              return NULL;
                }
/*->*/         return newClass;
            }
        }else{
            NSUInteger i=0;
            
            do{
                newClassStr = [NSString stringWithFormat:FORMAT,objClassStr,[@(i) stringValue]];
                newClass = NSClassFromString(newClassStr);
                i++;
            }while(newClass);
            
        }
        
        newClass = objc_allocateClassPair([self class], [newClassStr UTF8String], 0);
        if (!newClass){
/*->*/       return newClass;
        }
        mm_error_flag=NO;
        blockOv();
        if (mm_error_flag){
/*->*/       return NULL;
        }
        objc_registerClassPair(newClass);
        return newClass;
    }

}

//
// MARK: - Primary
//
+ (Class) anonWithReuserID:(NSString*)reuseID{
    Class newClass=nil;
    NSString *objClassStr= NSStringFromClass([self class]);
    NSString *FORMAT=@"%@_anon_%@";
    NSString *newClassStr =nil;
    if (reuseID) {
        reuseID = [[reuseID componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
        newClassStr = [NSString stringWithFormat:FORMAT,objClassStr,reuseID];
        newClass = NSClassFromString(newClassStr);
    }
    return newClass;
}
    
+ (id)allocAnon:(void(^)())blockOv{
   return [self allocAnonWithReuserID:nil :blockOv];
}
+ (id)    allocAnonWithReuserID:(NSString*)reuseID :(void(^)())blockOv{
    Class newClass=[self anonClass:blockOv reuseID:reuseID];
    id inst =[newClass alloc];
    newClass =nil;
    return inst;
    
}
+ (id)newInstAnon:(void(^)())blockOv{
    return [self newInstAnonWithReuseID:nil :blockOv];
}

+ (id)    newInstAnonWithReuseID:(NSString*)reuseID :(void(^)())blockOv{
    return  [[[self class] allocAnonWithReuserID:reuseID :blockOv] init];
}
//
// MARK: - Deprecated!
//
-(id) modifyMethods:(void(^)())blockOv{
    Class newClass=[[self class] anonClass:blockOv reuseID:nil];
    object_setClass(self, newClass);
    return self;
}
-(id) addMethod:(SEL)sel fromProtocol:(Protocol *)p isRequired:(BOOL)isReq blockImp:(id)block{
    return [self modifyMethods:^{
        ADD_METHOD(sel, p, block);
    }];
}
-(id) overrideMethod:(SEL)sel blockImp:(id)block{
    return [self modifyMethods:^{
        OVERRIDE(sel,  block);
    }];
}

-(IMP)removeInstanceMethod:  (SEL)sel{
        Class clas=[self class];
        Method method = class_getInstanceMethod(clas, sel);
        if (!method) {
                @throw [NSException exceptionWithName:kMMExeptionMethodError
                                                                reason:[NSString stringWithFormat: @"Method not found: %@",NSStringFromSelector(sel)]
                                                              userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
                return nil;
        }
        IMP oldImpl= method_setImplementation(method,(IMP)_objc_msgForward);
        return oldImpl;
}


@end
