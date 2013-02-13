//
//  MMTestClass.h
//  Runtime
//
//  Created by Boyko A.V. on 02.02.13.
//

#import <Foundation/Foundation.h>

@interface MMTestClass : NSObject{
    float property_;
}
@property (nonatomic) float floatProperty;
-(void)  voidMethod;
-(float) floatMethod:(float)param;
-(id)    objMethod:(id)param;
-(float) specialMethod:(float)param;
-(float) notOverridedMethod:(float)param;
@end
