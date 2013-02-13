//
//  NSObject+ObjecriveRuntime.m
//  Runtime
//
//  Created by Boyko A.V. on 02.02.13.
//

#import "NSObject+MMMutableMethod.h"
#import "MMProxy.h"
#import <objc/runtime.h>
#import <objc/message.h>

static char KEY; //key for 

@implementation NSObject(MMMutableMethod)



//
// MARK: - Swizzling
//
+(void)initialize{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method new = class_getInstanceMethod([NSObject class], @selector(newMethodSignatureForSelector:));
        Method old = class_getInstanceMethod([NSObject class], @selector(methodSignatureForSelector:));
        method_exchangeImplementations(new, old);
        
        new = class_getInstanceMethod([NSObject class], @selector(newDealloc));
        old = class_getInstanceMethod([NSObject class], @selector(dealloc));
        method_exchangeImplementations(new, old);
        
        new = class_getInstanceMethod([NSObject class], @selector(newForwardInvocation:));
        old = class_getInstanceMethod([NSObject class], @selector(forwardInvocation:));
        method_exchangeImplementations(new, old);
        
    });
}

-(void)newDealloc{
    NSMutableSet * set = objc_getAssociatedObject(self, &KEY);
    if (set!=nil) {
        for (NSString *strSel in set) {
            [self removeInstanceMethod:NSSelectorFromString(strSel)];
        }
        objc_removeAssociatedObjects(set);
    }
    
    [self newDealloc];
}

-(NSMethodSignature *)newMethodSignatureForSelector:(SEL)aSelector{
    NSMethodSignature *result = [self newMethodSignatureForSelector:aSelector];
    if (!result) {
        aSelector=[self modSelFor:aSelector];
        result=[self newMethodSignatureForSelector:aSelector];
    }
    return result;
}

- (void)newForwardInvocation:(NSInvocation *)anInvocation{
    //смотрим, а есть ли такой же метод, но уникальный
    SEL objSel=[self modSelFor:anInvocation.selector];
    //TODO: можно ускорить, используя получение IMP метода и сравнение его с  (IMP)_objc_msgForward
    //      если IMP == (IMP)_objc_msgForward, то у метода отсутствует imp
    //NSMethodSignature *objMethod=[self methodSignatureForSelector:objSel];
    IMP imp=class_getMethodImplementation([self class], objSel);
    
    BOOL selModify=NO;
    if (imp!=_objc_msgForward) {
        //если есть метод конкретно для этого объекта, то корректируем селектор
        anInvocation.selector=objSel;
        selModify=YES;
    }else{
        objSel=[self newInstSel:anInvocation.selector];
        imp=class_getMethodImplementation([self class], objSel);
        if (imp!=_objc_msgForward) {
            selModify=YES;
            anInvocation.selector=objSel;
        }
    }
    if ((imp!=_objc_msgForward)||(selModify)) {
        [anInvocation invokeWithTarget:self];
    }else{
        [self doesNotRecognizeSelector:anInvocation.selector];
    }
}

//
// MARK: - MMMutableMethod protocol
//
-(id)overrideMethod:(SEL)sel blockImp:(id)block{
    Class clas=[self class];
    
    Method method = class_getInstanceMethod(clas, sel);
    if (!method) {
        @throw [NSException exceptionWithName:kMMExeptionMethodNotFound
                                       reason:[NSString stringWithFormat: @"Method not found: %@",NSStringFromSelector(sel)]
                                     userInfo:@{kMMExeptionObject:self,kMMExeptionSelector:NSStringFromSelector(sel)}];
        return nil;
    }
    //генерируем данные для создания нового метода
    SEL newOvSel= [self modSelFor:sel];
    SEL newSelForInstMethod=[self newInstSel:sel];
    IMP newImp = imp_implementationWithBlock(block);
    BOOL resultOperation=NO;
    //проверяем, а есть ли уже такой метод (на случай если мы переопределяем уже ранее переопределяемый метод)
    Method newMethod = class_getInstanceMethod(clas, newOvSel);
    if (newMethod) {
        method_setImplementation(newMethod, newImp);
        resultOperation = YES;
    }else{
        resultOperation= class_addMethod(clas, newOvSel, newImp, method_getTypeEncoding(method));
        //запоминаем новый метод. После удаления объекта его нужно будет очистить
        if (resultOperation) {
            BOOL newSet = NO;
            NSMutableSet * set = objc_getAssociatedObject(self, &KEY);
            if (set==nil) {
                set=[NSMutableSet set];
                newSet=YES;
            }
            [set addObject:NSStringFromSelector(newOvSel)];
            if (newSet) {
                objc_setAssociatedObject(self,&KEY, set, OBJC_ASSOCIATION_RETAIN);
            }
            
        }
        
        Method instMethod = class_getInstanceMethod(clas, newSelForInstMethod);
        if (!instMethod) {
            IMP oldImp=[self removeInstanceMethod:sel];
            if (oldImp) {
                resultOperation=class_addMethod([self class], newSelForInstMethod, oldImp, method_getTypeEncoding(method));
            }
        }
    }
    //После того, как мы создали уникальный метод для этого объекта нужно уничтожить реализацию старого
    //метода, сделав копию но уже с другим именем
    if (!resultOperation) {
        
        @throw [NSException exceptionWithName:kMMExeptionMethodError
                                       reason:[NSString stringWithFormat: @"Can't override method %@",NSStringFromSelector(sel)]
                                     userInfo:@{kMMExeptionObject:self,kMMExeptionSelector:NSStringFromSelector(sel)}];
        return nil;
    }
    return self;
}

-(id) addMethod:(SEL)sel fromProtocol:(Protocol *)p isRequired:(BOOL)isReq blockImp:(id)block{
    Class clas=[self class];
    
    Method method = class_getInstanceMethod(clas, sel);
    if (method) {
        return [self overrideMethod:sel blockImp:block];
    }
    BOOL resultOperation = NO;
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
            }
            if (resultOperation) {
                BOOL newSet = NO;
                NSMutableSet * set = objc_getAssociatedObject(self, &KEY);
                if (set==nil) {
                    set=[NSMutableSet set];
                    newSet=YES;
                }
                [set addObject:NSStringFromSelector(newOvSel)];
                if (newSet) {
                    objc_setAssociatedObject(self,&KEY, set, OBJC_ASSOCIATION_RETAIN);
                }
                
            }
            
        }else{
            @throw [NSException exceptionWithName:kMMExeptionMethodNotFound
                                           reason:[NSString stringWithFormat: @"Method not found: %@",NSStringFromSelector(sel)]
                                         userInfo:@{kMMExeptionObject:self,kMMExeptionSelector:NSStringFromSelector(sel)}];
            return nil;

        }
    }

    if (!resultOperation) {
        @throw [NSException exceptionWithName:kMMExeptionMethodError
                                   reason:[NSString stringWithFormat: @"Can't add method %@",NSStringFromSelector(sel)]
                                 userInfo:@{kMMExeptionObject:self,kMMExeptionSelector:NSStringFromSelector(sel)}];
        return nil;
    }

    return self;
}

-(IMP)removeInstanceMethod:  (SEL)sel{
    Class clas=[self class];
    Method method = class_getInstanceMethod(clas, sel);
    if (!method) {
        @throw [NSException exceptionWithName:kMMExeptionMethodNotFound
                                       reason:[NSString stringWithFormat: @"Method not found: %@",NSStringFromSelector(sel)]
                                     userInfo:@{kMMExeptionObject:self,kMMExeptionSelector:NSStringFromSelector(sel)}];
        return nil;
    }
    IMP forw=class_getMethodImplementation(clas, @selector(methodThatDoesNotExist:iHope:::::));
    IMP oldImpl= method_setImplementation(method,forw);//(IMP)_objc_msgForward);
    return oldImpl;
}

-(void)removeAllObjectMethods{
    NSMutableSet * set = objc_getAssociatedObject(self, &KEY);
    if (set!=nil) {
        for (NSString *strSel in set) {
            [self removeInstanceMethod:NSSelectorFromString(strSel)];
        }
        objc_removeAssociatedObjects(set);
    }
}

//
// MARK: - Help methods
//
-(SEL)modSelFor:(SEL)defSel{
    const char *originalSel=sel_getName(defSel);
    char *address = malloc(sizeof(char)*100);
    sprintf(address, "%p",self);
    char* resultStr= malloc(sizeof(char)*(strlen(originalSel)+strlen(address)+1));
    sprintf(resultStr, "%s_%s",address,originalSel);
    
    SEL newSel = sel_getUid(resultStr);
    free(resultStr);
    free(address);
    return newSel;
    
    
}

-(SEL)newInstSel:(SEL)defSel{
    const char *originalSel=sel_getName(defSel);
    char  prefix[] = "mm_old_";
    char* resultStr= malloc(sizeof(char)*(strlen(originalSel)+strlen(prefix)));
    sprintf(resultStr, "%s%s",prefix,originalSel);
    SEL newSel = sel_getUid(resultStr);
    free(resultStr);
    return newSel;
    /* NSString *sel=NSStringFromSelector(defSel);
    NSString *selName = [NSString stringWithFormat:@"mm_old_%@",sel];
    return NSSelectorFromString(selName);*/
}

@end
