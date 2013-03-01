//
//  ORViewController.m
//  Runtime
//
//  Created by Boyko A.V. on 02.02.13.
//

#import "ORViewController.h"
#import "NSObject+MMAnonymousClass.h"
#import "UIOnClickListener.h"
#import <objc/message.h>
#import <QuartzCore/QuartzCore.h>
@interface ORViewController ()

@end

@implementation ORViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    
    //Объявляем делегат (объяснения по MMProxy ниже) //ds не освобождается. утечка
   
    
    //массив с данными для отображения
    items=[@[@"one",@"two",@"three", @"four",@"five"] mutableCopy];
   
    //переопределяем метод делегата (возвращающие количество секций, ячеек и сами ячейки)
    //ВАЖНО: параметр isRequired указывает является ли этот метод обязательным для протокола (@required)
    //или же нет (@option)
    //Этот параметр должен быть корректным

    NSObject *ds=nil;
   
    ds=[NSObject newInstAnon:^{
            ADD_METHOD(@selector(numberOfSectionsInTableView:),
                       @protocol(UITableViewDataSource),
                       ^NSUInteger(id object,UITableView*tb)
                       {
                           return 1;
                       });
            ADD_METHOD(@selector(tableView:numberOfRowsInSection:),
                       @protocol(UITableViewDataSource),
                       ^NSUInteger(id object,UITableView*tb)
                       {
                           return [items count];
                       });
            
            ADD_METHOD(@selector(tableView:cellForRowAtIndexPath:),
                       @protocol(UITableViewDataSource),
                       ^id(id object,UITableView*tb,NSIndexPath* indexPath)
                       {
                           static NSString *TableIdentifier = @"SimpleTableItem";
                           UITableViewCell *cell = [tb dequeueReusableCellWithIdentifier:TableIdentifier];
                           if (cell == nil)
                               cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableIdentifier];
                           
                           
                           cell.textLabel.text=items[indexPath.row];
                           return cell;
                       });
        }];

    self.tableView.dataSource=(id<UITableViewDataSource>)ds;
    id delegate =[NSObject newInstAnon:^{
        ADD_METHOD(@selector(tableView:didSelectRowAtIndexPath:),
                   @protocol(UITableViewDelegate),
                   ^(id selfObj,UITableView* tv,NSIndexPath* path)
                   {
                       NSLog(@"did select row %i",path.row);
                   });
        ADD_METHOD(@selector(tableView:willSelectRowAtIndexPath:),
                   @protocol(UITableViewDelegate),
                   ^NSIndexPath*(id selfObj,UITableView* tv,NSIndexPath* path)
                   {
                       NSLog(@"will select row %i",path.row);
                       return path;
                   });

    }];
    self.tableView.delegate=delegate;
    
    
    [self.tableView reloadData];
  
    UIButton *but= [UIButton buttonWithType:UIButtonTypeRoundedRect];
    but.frame=CGRectMake(0, 0, 50, 50);
    [self.view addSubview:but];
    [but addTarget:self
            action:@selector(onClick:)
  forControlEvents:UIControlEventTouchUpInside];
    
    
}
-(void)viewDidAppear:(BOOL)animated{
        return;

}
-(IBAction)onClick:(id)sender{
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Remove" message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"YES",nil];
   
    __block NSData *data = [[NSData dataWithContentsOfURL: [NSURL URLWithString:@"http://habrahabr.ru"] ] retain];
    id delegate = [NSObject newInstAnonWithReuseID:MM_DEFAULT_REUSE_ID :^{
        ADD_METHOD(@selector(alertView:clickedButtonAtIndex:),
                   @protocol(UIAlertViewDelegate),
                   ^void(id selfObj,UIAlertView* alertView,NSInteger index)
                   {
                       //[selfObj removeInstanceMethod:@selector(alertView:clickedButtonAtIndex:)];
                       alertView.delegate=nil;
                       [selfObj release];
                       [data release];
                        
                       if (index==0) {
                           return;
                       }
                       [items removeLastObject];
                       if ([items count]==0) {
                           [items addObjectsFromArray:@[@"one",@"two",@"three", @"four",@"five"]];
                       }
                       [self.tableView reloadData];
                      
                   });
    }];
    av.delegate=delegate;
    [av show];
    [av release];
    
    return;
    
    UIView *tmpView = [[UIView allocAnon:^{
        OVERRIDE(@selector(drawRect:), ^void(UIView *vie,CGRect rect){
            NSLog(@"%@",NSStringFromCGRect(rect));
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            CGContextSetLineWidth(context, 2.0);
            
            CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
            
            CGFloat components[] = {0.0, 0.0, 1.0, 1.0};
            
            CGColorRef color = CGColorCreate(colorspace, components);
            
            CGContextSetStrokeColorWithColor(context, color);
            
            CGContextMoveToPoint(context, 0, 0);
            CGContextAddLineToPoint(context, 300, 400);
            
            CGContextStrokePath(context);
            CGColorSpaceRelease(colorspace);
            CGColorRelease(color);
        });
    }] initWithFrame:CGRectMake(0, 100, 320, 380)];
    
   
    
    //UIView * tmpView2 =[[[tmpView class] alloc] initWithFrame:CGRectMake(0, 100, 320, 380)];
    [self.view addSubview:tmpView];
    //[self.view addSubview:tmpView2];
 
    [tmpView release];
    return;
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (index==0) {
        return;
    }
    [items removeLastObject];
    if ([items count]==0) {
        [items addObjectsFromArray:@[@"one",@"two",@"three", @"four",@"five"]];
    }
    [self.tableView reloadData];

}
-(IBAction)onClose:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_tableView release];
    [super dealloc];
}
@end
