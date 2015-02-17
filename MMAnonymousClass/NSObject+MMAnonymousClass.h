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

Class MM_ANON_CLASS(NSString *reuseID, Class superclass, void(^block)(__strong Class class));
id MM_ANON(NSString *reuseID, void(^block)(__strong Class class));

@interface NSObject (MMAnonymousClass)

+ (Class)subclassWithReuseID:(NSString *)reuseID
                 configBlock:(void(^)(Class))block;

+ (void)addMethod:(SEL)sel fromProtocol:(Protocol *)p blockImp:(id)block;
+ (void)addClassMethod:(SEL)sel blockImp:(id)block;
+ (void)overrideMethod:(SEL)sel blockImp:(id)block;
+ (void)removeMethod:(SEL)sel;
+ (void)removeClassMethod:(SEL)sel;

@end
