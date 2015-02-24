//
//  MMAnonymousClass.h
//  Runtime
//
//  Created by Anton Bukov on 24.02.15.
//  Copyright (c) 2015 Anton Bukov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMAnonymousClass;
id MM_ANON(void(^block)(MMAnonymousClass *anon));

@interface MMAnonymousClass : NSObject

+ (MMAnonymousClass *)anonWithBlock:(void(^)(MMAnonymousClass *anon))block;

- (void)addMethod:(SEL)sel fromProtocol:(Protocol *)proto blockImp:(id)block;
- (void)addMethod:(SEL)sel fromClass:(Class)class blockImp:(id)block;

@end
