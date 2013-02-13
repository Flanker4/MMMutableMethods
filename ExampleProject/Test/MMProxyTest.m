//
//  Test.m
//  Test
//
//  Created by Boyko A.V. on 02.02.13.
//

#import "MMProxyTest.h"
#import "MMProxy.h"
@implementation MMProxyTest

- (void)setUp{
    [super setUp];
    // Set-up code here.
    obj_=[MMTestClass new];
}

- (void)tearDown{
    // Tear-down code here.
    [obj_ release];
    obj_=nil;
    [super tearDown];
}

-(void)testOverrideVoidMethod{
    
    [obj_ voidMethod];
    [obj_ floatProperty];
    STAssertEquals(obj_.floatProperty, 0.0f, @"Дефолтная реализация voidMethod ничего не делает");
    
    MMProxy *proxy= [MMProxy proxyWithObject:obj_];
    [proxy overrideMethod:@selector(voidMethod) blockImp:^void(MMTestClass* selfObj){
        selfObj.floatProperty=10.0f;
    }];
    
    [(MMTestClass*)proxy voidMethod];
    STAssertEquals(((MMTestClass*)proxy).floatProperty, 10.0f, @"Переопределенная реализация устанавливает 10.0f");
}

-(void)testOverrideFloatMethod{
    STAssertEquals([obj_ floatMethod:2.0f], 2.0f, @"Ошибка");
    
    MMProxy *proxy= [MMProxy proxyWithObject:obj_];
    [proxy overrideMethod:@selector(floatMethod:) blockImp:^float(MMTestClass* selfObj,float prop){
        return 5.0f;
    }];
   
    STAssertEquals([(MMTestClass*)proxy floatMethod:10.0f], 5.0f, @"Ошибка");
    
}

-(void)testOverrideObjectMethod{
    
    id result = [obj_ objMethod:[[NSObject new] autorelease]];
    STAssertNotNil(result, @"Объект не должен быть nil");
    
    
    MMProxy *proxy= [MMProxy proxyWithObject:obj_];
    [proxy overrideMethod:@selector(objMethod:) blockImp:^id(MMTestClass* selfObj,id param){
        return nil;
    }];
    result = [(MMTestClass*)proxy objMethod:[[NSObject new] autorelease]];
    STAssertNil(result, @"Объект должен быть nil");
    
    
}

-(void)testOverridePropertyGet{
    obj_.floatProperty=2.0f;
    STAssertEquals(obj_.floatProperty, 2.0f, @"");
    
    MMProxy *proxy= [MMProxy proxyWithObject:obj_];
    [proxy overrideMethod:@selector(floatProperty) blockImp:^float(MMTestClass* selfObj){
        return 4.0f;
    }];
    STAssertEquals(((MMTestClass*)proxy).floatProperty, 4.0f, @"Измененная реализация должна возвращать 4");
   
}

-(void)testOverrideInvalidMethod{
    MMProxy *proxy= [MMProxy proxyWithObject:obj_];
    STAssertThrows(
                   [proxy overrideMethod:@selector(invalidMethod)
                                blockImp:^float(MMTestClass* selfObj)
                                {
                                    return 4.0f;
                                }],
                   @"При перегрузке несуществующего метода должно сгенерироваться сообщение");
    
}

-(void)testOverrideOv{
    STAssertEquals([obj_ floatMethod:2.0f], 2.0f, @"Ошибка");
    
    MMProxy *proxy= [MMProxy proxyWithObject:obj_];
    [proxy overrideMethod:@selector(floatMethod:) blockImp:^float(MMTestClass* selfObj,float prop){
        return 5.0f;
    }];
    STAssertEquals([(MMTestClass*)proxy floatMethod:10.0f], 5.0f, @"Ошибка");
    
    [proxy overrideMethod:@selector(floatMethod:) blockImp:^float(MMTestClass* selfObj,float prop){
        return 6.0f;
    }];
    STAssertEquals([(MMTestClass*)proxy floatMethod:10.0f], 6.0f, @"Ошибка");
}

-(void)testAddMethod{
    STAssertThrows([(id<UITableViewDataSource>)obj_ tableView:nil numberOfRowsInSection:0], @"Метод не существует");
    
    MMProxy* proxy = [MMProxy proxyWithObject:obj_];
    [proxy addMethod:@selector(tableView:numberOfRowsInSection:) fromProtocol:@protocol(UITableViewDataSource) isRequired:YES blockImp:^NSInteger(id selfObject, UITableView* tableView,NSUInteger section){
        return 10;
    }];
   
    STAssertNoThrow([(id<UITableViewDataSource>)proxy tableView:nil numberOfRowsInSection:0], @"Метод добавлен.");
    NSInteger result = 0;
    result=[(id<UITableViewDataSource>)proxy tableView:nil numberOfRowsInSection:0];
    STAssertEquals(result, (NSInteger)10, @"количество row==10");
}

-(void)testOverridePostEffect{
    MMProxy *proxy=[[MMProxy alloc]initWithObject:obj_];
    [proxy overrideMethod:@selector(specialMethod:) blockImp:^float(MMTestClass* selfObj,float prop){
        return 10.0f;
    }];
    STAssertEquals([(MMTestClass*)proxy specialMethod:2.0f], 10.0f, @"Должен равнятся 10.0f");
    [proxy release];

    proxy=[[MMProxy alloc]initWithObject:obj_];
    STAssertEquals([(MMTestClass*)proxy specialMethod:2.0f], 2.0f, @"Должен равнятся 2.0f, предыдущее переопределение должно быть уничтоженым");
    [proxy release];
}



@end
