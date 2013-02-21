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
BOOL OVERRIDE(SEL sel,id blockIMP);
BOOL ADD_METHOD(SEL sel,Protocol *p, BOOL isReq, id blockIMP);
BOOL ADD_METHOD_C(SEL sel,Class c,id blockIMP);

//cathegory
@interface NSObject(MMAnonymousClass)
+ (id)new:(void(^)())blockOv;
- (id)init:(void(^)())blockOv;
- (id)modifyMethods:(void(^)())blockOv;
-(id) addMethod:(SEL)sel fromProtocol:(Protocol *)p isRequired:(BOOL)isReq blockImp:(id)block;
-(id) overrideMethod:(SEL)sel blockImp:(id)block;

@end
