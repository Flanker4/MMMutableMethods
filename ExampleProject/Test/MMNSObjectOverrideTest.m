//
//  MMNSObjectOverrideTest.m
//  Runtime
//
//  Created by Boyko A.V. on 02.02.13.
//

#import "MMNSObjectOverrideTest.h"
#import "NSObject+MMAnonymousClass.h"
#import "MMTestClass.h"

@implementation MMNSObjectOverrideTest

-(void)setUp{
    [super setUp];
    obj_= [MMTestClass new];
}

- (void)tearDown{
    [obj_ release];
    [objAnonClass_ release];
    obj_=nil;
    objAnonClass_=nil;
    [super tearDown];
}

-(void)testOverrideVoidMethod{
    [obj_ voidMethod];
    STAssertEquals(obj_.floatProperty, 0.0f, @"Дефолтная реализация voidMethod ничего не делает");
    
    //create new ANON class
    objAnonClass_=[MMTestClass newInstAnonWithReuseID:MM_DEFAULT_REUSE_ID :^{
        OVERRIDE(@selector(voidMethod), ^void(MMTestClass* selfObj){
            selfObj.floatProperty=10.0f;
        });
    }];
    
    //test
    [objAnonClass_ voidMethod];
    STAssertEquals(objAnonClass_.floatProperty, 10.0f, @"Переопределенная реализация устанавливает 10.0f");
}

-(void)testOverrideFloatMethod{
    STAssertEquals([obj_ floatMethod:2.0f], 2.0f, @"Ошибка");
    
    //new inst of ANON class
    objAnonClass_=[MMTestClass newInstAnonWithReuseID:MM_DEFAULT_REUSE_ID :^{
        OVERRIDE(@selector(floatMethod:), ^float(MMTestClass* selfObj,float prop){
             return 200.0f;
        });
    }];
    //test
    STAssertEquals([objAnonClass_ floatMethod:10.0f], 200.0f, @"Ошибка");
    
}

-(void)testOverrideObjectMethod{
    id result = [obj_ objMethod:[[NSObject new] autorelease]];
    STAssertNotNil(result, @"Объект не должен быть nil");
    
    objAnonClass_=[MMTestClass newInstAnonWithReuseID:MM_DEFAULT_REUSE_ID :^{
        OVERRIDE(@selector(objMethod:), ^id(MMTestClass* selfObj,id param){
            return nil;
        });
    }];
    
    result = [objAnonClass_ objMethod:[[NSObject new] autorelease]];
    STAssertNil(result, @"Объект должен быть nil");
}

-(void)testOverridePropertyGet{
    obj_.floatProperty=2.0f;
    STAssertEquals(obj_.floatProperty, 2.0f, @"");
    
    //new inst of ANON class
    objAnonClass_=[MMTestClass newInstAnonWithReuseID:MM_DEFAULT_REUSE_ID :^{
        OVERRIDE(@selector(floatProperty), ^float(MMTestClass* selfObj){
            return 4.0f;
        });
    }];
    STAssertEquals(objAnonClass_.floatProperty, 4.0f, @"Измененная реализация должна возвращать 4");
    
}

-(void)testOverrideInvalidMethod{
     STAssertThrows([MMTestClass newInstAnonWithReuseID:MM_DEFAULT_REUSE_ID :^{
                        OVERRIDE(@selector(invalidMethod), ^float(MMTestClass* selfObj){
                                return 0.0f;
                        });
                     }],
                   @"При перегрузке несуществующего метода должно сгенерироваться сообщение");
    
}

-(void)testOverrideOfOverride{
    STAssertEquals([obj_ floatMethod:2.0f], 2.0f, @"Ошибка");
    
    objAnonClass_=[MMTestClass newInstAnonWithReuseID:MM_DEFAULT_REUSE_ID :^{
        OVERRIDE(@selector(floatMethod:), ^float(MMTestClass* selfObj,float prop){
            return 5.0f;
        });
    }];
    STAssertEquals([objAnonClass_ floatMethod:10.0f], 5.0f, @"Ошибка");
    [objAnonClass_ release];
    
    objAnonClass_=[MMTestClass newInstAnonWithReuseID:MM_DEFAULT_REUSE_ID :^{
        OVERRIDE(@selector(floatMethod:), ^float(MMTestClass* selfObj,float prop){
            return 6.0f;
        });
    }];
    STAssertEquals([objAnonClass_ floatMethod:10.0f], 6.0f, @"Ошибка");
}

-(void)testAddMethod{
    STAssertThrows([(id<UITableViewDataSource>)obj_ tableView:nil numberOfRowsInSection:0], @"Метод не существует");
    
    objAnonClass_=[MMTestClass newInstAnonWithReuseID:MM_DEFAULT_REUSE_ID :^{
        ADD_METHOD(@selector(tableView:numberOfRowsInSection:),
                   @protocol(UITableViewDataSource),
                   ^NSInteger(id selfObject, UITableView* tableView,NSUInteger section){
                       return 10;
                   });
    }];
    
    STAssertNoThrow([(id<UITableViewDataSource>)objAnonClass_ tableView:nil numberOfRowsInSection:0], @"Метод добавлен.");
    NSInteger result = 0;
    result=[(id<UITableViewDataSource>)objAnonClass_ tableView:nil numberOfRowsInSection:0];
    STAssertEquals(result, (NSInteger)10, @"количество row==10");
}

-(void)testDefaultReuseID{
    Class testClass=NULL;
    for (int i=0; i<100; i++) {
        objAnonClass_=[MMTestClass newInstAnonWithReuseID:MM_DEFAULT_REUSE_ID :^{
            OVERRIDE(@selector(floatMethod:), ^float(MMTestClass* selfObj,float prop){
                return 6.0f;
            });
        }];
        STAssertEquals([objAnonClass_ floatMethod:1.0f], 6.0f, @"Error");
        if (testClass==NULL) {
            testClass=[objAnonClass_ class];
        }
        STAssertTrue([objAnonClass_ isMemberOfClass:testClass], @"Error");

        [objAnonClass_ release];
        objAnonClass_=nil;
    }

}
-(void)testCustomReuseID{
    Class testClass=NULL;
    for (int i=0; i<100; i++) {
        objAnonClass_=[MMTestClass newInstAnonWithReuseID:@"Go Go" :^{
            OVERRIDE(@selector(floatMethod:), ^float(MMTestClass* selfObj,float prop){
                return 6.0f;
            });
        }];
        STAssertEquals([objAnonClass_ floatMethod:1.0f], 6.0f, @"Error");
        if (testClass==NULL) {
            testClass=[objAnonClass_ class];
        }
        STAssertTrue([objAnonClass_ isMemberOfClass:testClass], @"Error");
        
        [objAnonClass_ release];
        objAnonClass_=nil;
    }
    
}

-(void) testAnonClassFromReuseID{
    objAnonClass_=[MMTestClass newInstAnonWithReuseID:@"Go Go" :^{
        OVERRIDE(@selector(floatMethod:), ^float(MMTestClass* selfObj,float prop){
            return 6.0f;
        });
    }];
    Class testClass = [objAnonClass_ class];
    [objAnonClass_ release];
   
    objAnonClass_=[[[MMTestClass anonWithReuserID:@"Go Go"] alloc] init];
    STAssertTrue([objAnonClass_ isMemberOfClass:testClass], @"Error");

}


@end

