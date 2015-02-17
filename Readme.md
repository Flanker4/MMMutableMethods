MMMutableMethods
========

##Installation

```
pod 'MMMutableMethods', :branch => 'dev'
```

##Usage

Following code will create new NSObject subclass and add methods **once**, no matter how many times this code will execute.

```
[cmd startWithAMCommandCallback:MM_ANON(MM_REUSE,^(Class class){
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
})];
```
