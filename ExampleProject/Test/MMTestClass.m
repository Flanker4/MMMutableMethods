//
//  MMTestClass.m
//  Runtime
//
//  Created by Boyko A.V. on 02.02.13.
//

#import "MMTestClass.h"

@implementation MMTestClass
@synthesize floatProperty=property_;

-(id)init{
    self=[super init];
    if (self) {
        property_=0.0f;
    }
    return self;
}

-(void)  voidMethod{
    NSLog(@"[MMTestClass voidMethod]");
}

-(float) floatMethod:(float)param{
    return param;
}
-(id)    objMethod:(id)param{
    return param;
}
-(float)specialMethod:(float)param{
    return param;
}
-(float) notOverridedMethod:(float)param{
    return param;
}
@end
