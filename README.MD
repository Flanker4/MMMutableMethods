MMMutableMethods
========

Simple library to declare anonymous classes in Objective-C runtime, dynamically add methods and class methods.

##Installation

```
pod 'MMMutableMethods', :git => 'https://github.com/k06a/MMMutableMethods', :branch => 'dev'
```

##Usage

Following code will create new NSObject subclass and add methods **once**, no matter how many times this code will execute.

```
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
