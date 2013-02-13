//
//  OROnClickListener.m
//  Runtime
//
//  Created by Boyko A.V. on 02.02.13.
//

#import "UIOnClickListener.h"

@implementation UIOnClickListener
-(id) init{
    UIClickTarget *obj=[[UIClickTarget new] autorelease];
    return [self initWithObject:obj];
}
+(id)new{
    return [[[self class] alloc] init];
}
-(void)dealloc{
    [super dealloc];
}
@end

@implementation UIClickTarget
-(IBAction)onClick:(id)sender{
    NSLog(@"default imp");
}
@end