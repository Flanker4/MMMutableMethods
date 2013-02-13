//
//  ORMutableMethod.h
//  Runtime
//
//  Created by Boyko A.V. on 05.02.13.
//

#import <Foundation/Foundation.h>



@protocol MMMutableMethod <NSObject>
@required
-(id) overrideMethod:        (SEL)sel  blockImp:(id)block;
-(id) addMethod:             (SEL)sel
   fromProtocol:(Protocol*)p
     isRequired:(BOOL)isReq
       blockImp:(id)block;
-(IMP) removeInstanceMethod:  (SEL)sel;
-(void)removeAllObjectMethods;
@end
