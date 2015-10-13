//
//  MMAnonymousClass.m
//  Runtime
//
//  Created by Anton Bukov on 24.02.15.
//  Copyright (c) 2015 Anton Bukov. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "MMAnonymousClass.h"

id MM_ANON(void(^block)(MMAnonymousClass *anon))
{
    return [MMAnonymousClass anonWithBlock:block];
}

@interface MMAnonymousClass ()

@property (nonatomic, strong) NSMutableDictionary *blocks;
@property (nonatomic, strong) NSMutableDictionary *protocols;
@property (nonatomic, strong) NSMutableDictionary *classes;

@end

@implementation MMAnonymousClass

- (NSMutableDictionary *)blocks
{
    if (_blocks == nil)
        _blocks = [NSMutableDictionary dictionary];
    return _blocks;
}

- (NSMutableDictionary *)protocols
{
    if (_protocols == nil)
        _protocols = [NSMutableDictionary dictionary];
    return _protocols;
}

- (NSMutableDictionary *)classes
{
    if (_classes == nil)
        _classes = [NSMutableDictionary dictionary];
    return _classes;
}

- (const char *)typesForSelector:(SEL)sel
{
    NSString *protoStr = self.protocols[NSStringFromSelector(sel)];
    if (protoStr) {
        Protocol *proto = NSProtocolFromString(protoStr);
        struct objc_method_description descript = protocol_getMethodDescription(proto, sel, NO, YES);
        if (descript.types == nil)
            descript = protocol_getMethodDescription(proto, sel, YES, YES);
        return descript.types;
    }
    
    NSString *classStr = self.classes[NSStringFromSelector(sel)];
    if (classStr) {
        Class class = NSClassFromString(classStr);
        Method method = class_getInstanceMethod(class, sel);
        if (method)
            return method_getTypeEncoding(method);
    }
    
    return nil;
}

#pragma mark - Public Methods

+ (MMAnonymousClass *)anonWithBlock:(void(^)(MMAnonymousClass *anon))block
{
    MMAnonymousClass *anon = [[MMAnonymousClass alloc] init];
    block(anon);
    return anon;
}

- (void)addMethod:(SEL)sel fromProtocol:(Protocol *)proto blockImp:(id)block
{
    NSString *selStr = NSStringFromSelector(sel);
    self.blocks[selStr] = block;
    self.protocols[selStr] = NSStringFromProtocol(proto);
}

- (void)addMethod:(SEL)sel fromClass:(Class)class blockImp:(id)block
{
    NSString *selStr = NSStringFromSelector(sel);
    self.blocks[selStr] = block;
    self.classes[selStr] = NSStringFromClass(class);
}

#pragma mark - Messsage Forwarding

- (BOOL)respondsToSelector:(SEL)aSelector
{
    for (NSString *key in self.blocks)
        if (NSSelectorFromString(key) == aSelector)
            return YES;
    return [super respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    const char *types = [self typesForSelector:aSelector];
    return [NSMethodSignature signatureWithObjCTypes:types];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    for (NSString *key in self.blocks) {
        if (NSSelectorFromString(key) == anInvocation.selector) {
            id block = self.blocks[key];
            anInvocation.selector = nil;
            [anInvocation invokeWithTarget:block];
            return;
        }
    }
    return [super forwardInvocation:anInvocation];
}

@end
