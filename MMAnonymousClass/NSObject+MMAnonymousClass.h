//
//  NSObject+MMAnonymousClass.h
//  Runtime
//
//  Created by Boyko A.V. on 21.02.13.
//  Copyright (c) 2013 LOL. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kMMExeptionMethodError;
extern NSString *const kMMExeptionSelector;

#define MM_REUSE [NSString stringWithFormat:@"%s_%d", __PRETTY_FUNCTION__, __LINE__]

Class MM_CREATE_CLASS(NSString *reuseID, Class superclass, void(^block)(__strong Class class));
Class MM_CREATE_CLASS_ALWAYS(Class superclass, void(^block)(__strong Class class));
id MM_CREATE(NSString *reuseID, void(^block)(__strong Class class));
id MM_CREATE_ALWAYS(void(^block)(__strong Class class));

@interface NSObject (MMAnonymousClass)

+ (Class)subclassWithReuseID:(NSString *)reuseID
                 configBlock:(void(^)(Class))block;

+ (void)addMethod:(SEL)sel fromProtocol:(Protocol *)p blockImp:(id)block;
+ (void)addMethod:(SEL)sel fromClass:(Class)class blockImp:(id)block;
+ (void)overrideMethod:(SEL)sel blockImp:(id)block;
+ (void)removeMethod:(SEL)sel __attribute__((deprecated));
+ (void)removeClassMethod:(SEL)sel __attribute__((deprecated));
+ (void)deleteClass;

@end
