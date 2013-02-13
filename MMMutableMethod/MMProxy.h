//
//  ORProxy.h
//  Runtime
//
//  Created by Boyko A.V. on 02.02.13.
//

#import <Foundation/Foundation.h>
#import "MMMutableMethod.h"

extern NSString *const kMMExeptionMethodNotFound;
extern NSString *const kMMExeptionMethodError;
extern NSString *const kMMExeptionObject;
extern NSString *const kMMExeptionSelector;


@interface MMProxy : NSProxy<MMMutableMethod>{
    id object_;
    NSMutableSet *ovMethods_;
}
@property (nonatomic,readonly) id object;

-(id) initWithObject:(NSObject*)object;
+(id) proxyWithObject:(NSObject*)object;
+(id) proxyWithMMObject;
@end


@interface MMObject : NSObject
-(void)testMethod;
@end
