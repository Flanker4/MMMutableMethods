//
//  NSString+AllowCharactersInSet.h
//  Runtime
//
//  Created by Ryan
//  http://stackoverflow.com/users/56301/ryan
//

#import <Foundation/Foundation.h>

@interface NSString (AllowCharactersInSet)
- (NSString *)stringByAllowingOnlyCharactersInSet:(NSCharacterSet *)characterSet;
@end
