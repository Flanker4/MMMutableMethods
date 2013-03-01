//
//  ORViewController.h
//  Runtime
//
//  Created by Boyko A.V. on 02.02.13.
//

#import <UIKit/UIKit.h>

@interface ORViewController : UIViewController<UIAlertViewDelegate>{
    NSMutableArray *items;
}
@property (retain, nonatomic) IBOutlet UITableView *tableView;

@end
