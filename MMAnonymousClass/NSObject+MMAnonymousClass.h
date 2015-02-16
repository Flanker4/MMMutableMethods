//
//  NSObject+MMAnonymousClass.h
//  Runtime
//
//  Created by Boyko A.V. on 21.02.13.
//  Copyright (c) 2013 LOL. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MM_DEFAULT_REUSE_ID  [NSString stringWithFormat:@"%s_%d", __PRETTY_FUNCTION__, __LINE__]

// ANON_C(NSObject, ^(Class class) { ... })
#define ANON_C(class, block) \
        [class subclassWithReuseID:MM_DEFAULT_REUSE_ID configBlock:(block)]

// ANON(^(Class class) { ... })
#define ANON(block) \
        ANON_C(NSObject, (block))

// ANONOBJ_C(NSObject, ^(Class class) { ... })
#define ANONOBJ_C(class, block) \
        ((id)[[ANON_C(class, block) alloc] init])

// ANONOBJ(^(Class class) { ... })
#define ANONOBJ(block) \
        ((id)[[ANON(block) alloc] init])

extern NSString *const kMMExeptionMethodError;
extern NSString *const kMMExeptionSelector;

@interface NSObject (MMAnonymousClass)

+ (Class)subclassWithReuseID:(NSString *)reuseID
                 configBlock:(void(^)(Class))block;

+ (void)addMethod:(SEL)sel fromProtocol:(Protocol *)p blockImp:(id)block;
+ (void)addClassMethod:(SEL)sel blockImp:(id)block;
+ (void)overrideMethod:(SEL)sel blockImp:(id)block;
+ (void)removeMethod:(SEL)sel;
+ (void)removeClassMethod:(SEL)sel;

@end
