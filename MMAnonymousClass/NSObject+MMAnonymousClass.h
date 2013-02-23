//
//  NSObject+MMAnonymousClass.h
//  Runtime
//
//  Created by flanker on 21.02.13.
//  Copyright (c) 2013 LOL. All rights reserved.
//

#import <Foundation/Foundation.h>



//@throw
extern NSString *const kMMExeptionMethodError;
extern NSString *const kMMExeptionSelector;
//c help func
extern  inline BOOL OVERRIDE     (SEL sel,id blockIMP);
extern  inline BOOL ADD_METHOD   (SEL sel,Protocol *p, BOOL isReq, id blockIMP);
extern  inline BOOL ADD_METHOD_C (SEL sel,Class c,id blockIMP);

//cathegory
@interface NSObject(MMAnonymousClass)

//
// MARK: - DEPRECATED!
//
- (id) modifyMethods:   (void(^)())blockOv __attribute__((deprecated));
- (id) addMethod:       (SEL)sel fromProtocol:(Protocol *)p isRequired:(BOOL)isReq blockImp:(id)block __attribute__((deprecated));
- (id) overrideMethod:  (SEL)sel blockImp:(id)block __attribute__((deprecated));
//
// MARK: - Allowed
//
//+ (Class) anonClass:        (void(^)())blockOv;
+ (id)    allocAnonClass:   (void(^)())blockOv;
+ (id)    newInstAnonClass: (void(^)())blockOv;
@end
