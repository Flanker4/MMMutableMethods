//
//  OROnClickListener.h
//  Runtime
//
//  Created by Boyko A.V. on 02.02.13.
//

#import <Foundation/Foundation.h>
#import "MMProxy.h"

@interface UIOnClickListener : MMProxy
-(id)init;
+(id)new;
@end

@interface UIClickTarget : NSObject
-(IBAction)onClick:(id)sender;
@end

