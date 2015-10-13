MMMutableMethods
========

Simple library to declare anonymous classes in Objective-C runtime, dynamically add methods and class methods.

##Installation

```
pod 'MMMutableMethods', :git => 'https://github.com/k06a/MMMutableMethods'
```

##Usage

First mechanism works on obj-c runtime class creation:

```
#import <MMMutableMethods/NSObject+MMAnonymousClass.h>

MM_CREATE(MM_REUSE,^(Class class){
    [class addMethod:@selector(onResultWithId:)
        fromProtocol:@protocol(AMCommandCallback)
            blockImp:^(id this,id res){
                NSLog(@"onResultWithId: %@",res);
            }];
    [class addMethod:@selector(onErrorWithJavaLangException:)
        fromProtocol:@protocol(AMCommandCallback)
            blockImp:^(id this,JavaLangException *e){
                NSLog(@"onErrorWithJavaLangException: %@",e);
            }];
})
```

Second mechanism works on simple message forward implementation:

```
#import <MMMutableMethods/MMAnonymousClass.h>

[cmd startWithAMCommandCallback:MM_ANON(^(MMAnonymousClass *anon){
    [anon addMethod:@selector(onResultWithId:)
       fromProtocol:@protocol(AMCommandCallback)
           blockImp:^(id this,id res){
               NSLog(@"onResultWithId: %@",res);
           }];
    [anon addMethod:@selector(onErrorWithJavaLangException:)
       fromProtocol:@protocol(AMCommandCallback)
           blockImp:^(id this,JavaLangException *e){
               NSLog(@"onErrorWithJavaLangException: %@",e);
           }];
})];
```

First one crates new obc-j classes in runtime, it allows you to create classes `MM_CREATE_CLASS(MM_REUSE, *)` and directly instances with `MM_CREATE(MM_REUSE, *)`. Classes will be created only on first execution and reused by default, but you can avoid reusing by calling `MM_CREATE_CLASS_ALWAYS(*)` and `MM_CREATE_ALWAYS(*)`.

The second mechanism doesn't creates any runtime instances, just remember blocks for selectors and forward method calls to them.

I prefere second way not to create a lot of classes in runtime. IMHO it is much safer and enough powerful.