//
//  NSObject+MMAnonymousClass.h
//  Runtime
//
//  Created by Boyko A.V. on 21.02.13.
//  Copyright (c) 2013 LOL. All rights reserved.
//

#import <Foundation/Foundation.h>


#define MM_DEFAULT_REUSE_ID  [NSString stringWithFormat:@"%s_%d", __PRETTY_FUNCTION__, __LINE__]

//@throw
extern NSString *const kMMExeptionMethodError;
extern NSString *const kMMExeptionSelector;
//c help func
extern  inline BOOL OVERRIDE     (SEL sel,id blockIMP);
extern  inline BOOL ADD_METHOD   (SEL sel,Protocol *p, id blockIMP);
extern  inline BOOL ADD_METHOD_C (SEL sel,Class c,id blockIMP);

//cathegory
@interface NSObject(MMAnonymousClass)

//
// MARK: - DEPRECATED!
//
- (id) modifyMethods:   (void(^)())blockOv __attribute__((deprecated));
- (id) addMethod:       (SEL)sel fromProtocol:(Protocol *)p isRequired:(BOOL)isReq blockImp:(id)block __attribute__((deprecated));
- (id) overrideMethod:  (SEL)sel blockImp:(id)block __attribute__((deprecated));
- (IMP)removeInstanceMethod:  (SEL)sel;
//
// MARK: - Allowed
//
+ (Class) anonWithReuserID:         (NSString*)reuseID;
+ (id)    allocAnon:                (void(^)())blockOv              __attribute__((deprecated));

+ (id)    allocAnonWithReuserID:    (NSString*)reuseID :(void(^)())blockOv;
+ (id)    newInstAnon:              (void(^)())blockOv              __attribute__((deprecated));
+ (id)    newInstAnonWithReuseID:(NSString*)reuseID :(void(^)())blockOv;
@end
