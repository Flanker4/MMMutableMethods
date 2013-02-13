//
//  ORProxy.m
//  Runtime
//
//  Created by Boyko A.V. on 02.02.13.
//

#import "MMProxy.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString *const kMMExeptionMethodNotFound       = @"MMExeptionMethodNotFound";
NSString *const kMMExeptionMethodError          = @"MMExeptionMethodError";
NSString *const kMMExeptionObject               = @"MMExeptionObject";
NSString *const kMMExeptionSelector             = @"MMExeptionSelector";

@implementation MMProxy
@synthesize object=object_;

-(id)initWithObject:(NSObject *)object{
    if (object==nil) {
        return nil;
    }
    object_=[object retain];
    ovMethods_=[[NSMutableSet set] retain];
    return self;
}

+(id)proxyWithObject:(NSObject *)object{
    MMProxy *proxy=[[[MMProxy alloc] initWithObject:object] autorelease];
    return proxy;
}

+(id)proxyWithMMObject{
    NSObject *tmpObject=[MMObject new];
    id obj = [MMProxy proxyWithObject:tmpObject];
    [tmpObject release];
    return obj;
}

-(void)dealloc{
    [self removeAllObjectMethods];
    [object_ release];
    [ovMethods_ release];
    [super dealloc];
}

//
// MARK: - ORMutableMethod
//
-(void)removeAllObjectMethods{
    for (NSString *strSel in ovMethods_) {
        [self removeInstanceMethod:NSSelectorFromString(strSel)];
    }
    [ovMethods_ removeAllObjects];
}

-(id) overrideMethod:(SEL)sel  blockImp:(id)block{
    Class clas=[object_ class];;
    
    Method method = class_getInstanceMethod(clas, sel);
    if (!method) {
        @throw [NSException exceptionWithName:kMMExeptionMethodNotFound
                                       reason:[NSString stringWithFormat: @"Method not found: %@",NSStringFromSelector(sel)]
                                     userInfo:@{kMMExeptionObject:self.object,kMMExeptionSelector:NSStringFromSelector(sel)}];
        return nil;
    }
    //генерируем данные для создания нового метода
    SEL newOvSel= [self modSelFor:sel];
    IMP newImp = imp_implementationWithBlock(block);
    BOOL resultOperation=NO;
    //проверяем, а есть ли уже такой метод (на случай если мы переопределяем уже ранее переопределяемый метод)
    Method newMethod = class_getInstanceMethod(clas, newOvSel);
    if (newMethod) {
        method_setImplementation(newMethod, newImp);
        resultOperation = YES;
    }else{
        resultOperation= class_addMethod(clas, newOvSel, newImp, method_getTypeEncoding(method));
        [ovMethods_ addObject:NSStringFromSelector(newOvSel)];
    }
    if (!resultOperation) {
        @throw [NSException exceptionWithName:kMMExeptionMethodError
                                       reason:[NSString stringWithFormat: @"Can't override method %@",NSStringFromSelector(sel)]
                                     userInfo:@{kMMExeptionObject:self.object,kMMExeptionSelector:NSStringFromSelector(sel)}];
        return nil;
    }
    return self;

}

-(id) addMethod:     (SEL)sel  fromProtocol:(Protocol*)p isRequired:(BOOL)isReq blockImp:(id)block{
    Class clas=[object_ class];
    Method method = class_getInstanceMethod(clas, sel);
    BOOL resultOperation=NO;
    if (method) {
       return [self overrideMethod:sel blockImp:block];
    }else{
        if (p) {
            struct objc_method_description descript=protocol_getMethodDescription(p, sel, isReq, YES);
            if (descript.types!=NULL) {
                SEL newOvSel= [self modSelFor:sel];
                IMP newImp = imp_implementationWithBlock(block);
                //проверяем, а есть ли уже такой метод (на случай если мы переопределяем уже ранее переопределяемый метод)
                Method newMethod = class_getInstanceMethod(clas, newOvSel);
                if (newMethod) {
                    method_setImplementation(newMethod, newImp);
                    resultOperation = YES;
                }else{
                    resultOperation=class_addMethod(clas, newOvSel, newImp, descript.types);
                    [ovMethods_ addObject:NSStringFromSelector(newOvSel)];
                }                
            }
        }
    }
    if (!resultOperation) {
        @throw [NSException exceptionWithName:kMMExeptionMethodError
                                       reason:[NSString stringWithFormat: @"Can't add method %@",NSStringFromSelector(sel)]
                                     userInfo:@{kMMExeptionObject:self.object,kMMExeptionSelector:NSStringFromSelector(sel)}];
        return nil;
    }
    return self;
}

-(IMP)removeInstanceMethod:  (SEL)sel{
    Class clas=[object_ class];
    Method method = class_getInstanceMethod(clas, sel);
    if (!method) {
        @throw [NSException exceptionWithName:kMMExeptionMethodNotFound
                                       reason:[NSString stringWithFormat: @"Method not found: %@",NSStringFromSelector(sel)]
                                     userInfo:@{kMMExeptionObject:self.object,kMMExeptionSelector:NSStringFromSelector(sel)}];
        return nil;
    }
    //IMP forw=class_getMethodImplementation(clas, @selector(methodThatDoesNotExist:iHope:::::));
    IMP oldImpl= method_setImplementation(method,(IMP)_objc_msgForward);
    return oldImpl;
}


//
// MARK: - Method forwanding
//
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *mSignature = [self.object methodSignatureForSelector:aSelector];
    if (!mSignature) {
        aSelector=[self modSelFor:aSelector];
        mSignature=[self.object methodSignatureForSelector:aSelector];
    }
    return mSignature;
}

// Invoke the invocation on whichever real object had a signature for it.
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSMethodSignature *method=[self.object methodSignatureForSelector:anInvocation.selector];
    
    NSString *sel=NSStringFromSelector(anInvocation.selector);
    NSString *adress=[NSString stringWithFormat:@"%p",self.object];

    if ([sel hasPrefix:adress]) {
        //если это вызов метода объекта
        if (method) {
            [anInvocation invokeWithTarget:self.object];
        }else{
            [self.object doesNotRecognizeSelector:anInvocation.selector];
        }
    }else{
        //иначе смотрим, а есть ли такой же метод, но уникальный
        SEL objSel= [self modSelFor:anInvocation.selector];
        //NSMethodSignature *objMethod=[self.object methodSignatureForSelector:objSel];
        IMP imp=class_getMethodImplementation([self.object class], objSel);
        BOOL selModify=NO;
        if (imp!=_objc_msgForward) {
            //если есть метод конкретно для этого объекта, то корректируем селектор
            anInvocation.selector=objSel;
            selModify=YES;
        }
        if ((method)||(selModify)) {
            [anInvocation invokeWithTarget:self.object];
        }else{
            [self.object doesNotRecognizeSelector:anInvocation.selector];
        }
    }
}
- (BOOL)respondsToSelector:(SEL)aSelector {
    if (([object_ respondsToSelector:aSelector])||([object_ respondsToSelector:[self modSelFor:aSelector]]))
        return YES;
    return NO;
}
-(SEL)modSelFor:(SEL)defSel{
    NSString *adress=[NSString stringWithFormat:@"%p",self.object];
    NSString *sel=NSStringFromSelector(defSel);
    NSString *selName = [NSString stringWithFormat:@"%@_%@",adress,sel];
    return NSSelectorFromString(selName);
}

//
// MARK: - NSObject protocol
//
-(BOOL) isProxy{
    return YES;
}

-(BOOL)isObject{
    return NO;
}
@end


@implementation MMObject
-(void)testMethod{
    NSLog(@"[self testMethod];");
}
@end
