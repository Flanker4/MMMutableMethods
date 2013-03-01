//
//  NSString+AllowCharactersInSet.m
//  Runtime
//
//  Created by Ryan 
//  http://stackoverflow.com/users/56301/ryan
//

#import "NSString+AllowCharactersInSet.h"

@implementation NSString (AllowCharactersInSet)
- (NSString *)stringByAllowingOnlyCharactersInSet:(NSCharacterSet *)characterSet {
    NSMutableString *strippedString = [NSMutableString
                                       stringWithCapacity:self.length];
    
    NSScanner *scanner = [NSScanner scannerWithString:self];
    
    while (!scanner.isAtEnd) {
        NSString *buffer = nil;
        
        if ([scanner scanCharactersFromSet:characterSet intoString:&buffer]) {
            [strippedString appendString:buffer];
        } else {
            scanner.scanLocation = scanner.scanLocation + 1;
        }
    }
    
    return strippedString;
}
@end
