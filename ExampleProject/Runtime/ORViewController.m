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
    NSArray *arr=@[@"one",@"two",@"three", @"four",@"five"];
   
    //переопределяем метод делегата (возвращающие количество секций, ячеек и сами ячейки)
    //ВАЖНО: параметр isRequired указывает является ли этот метод обязательным для протокола (@required)
    //или же нет (@option)
    //Этот параметр должен быть корректным

    NSObject *ds=nil;
   
    ds=[NSObject newInstAnonClass:^{
            ADD_METHOD(@selector(numberOfSectionsInTableView:),
                       @protocol(UITableViewDataSource),
                       NO,
                       ^NSUInteger(id object,UITableView*tb)
                       {
                           return 1;
                       });
            ADD_METHOD(@selector(tableView:numberOfRowsInSection:),
                       @protocol(UITableViewDataSource),
                       YES,
                       ^NSUInteger(id object,UITableView*tb)
                       {
                           return [arr count];
                       });
            
            ADD_METHOD(@selector(tableView:cellForRowAtIndexPath:),
                       @protocol(UITableViewDataSource),
                       YES,
                       ^id(id object,UITableView*tb,NSIndexPath* indexPath)
                       {
                           static NSString *TableIdentifier = @"SimpleTableItem";
                           UITableViewCell *cell = [tb dequeueReusableCellWithIdentifier:TableIdentifier];
                           if (cell == nil)
                               cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableIdentifier];
                           
                           
                           cell.textLabel.text=arr[indexPath.row];
                           return cell;
                       });
        }];

    self.tableView.dataSource=(id<UITableViewDataSource>)ds;
    id delegate =[NSObject newInstAnonClass:^{
        ADD_METHOD(@selector(tableView:didSelectRowAtIndexPath:),
                   @protocol(UITableViewDelegate),
                   NO,
                   ^(id selfObj,UITableView* tv,NSIndexPath* path)
                   {
                       NSLog(@"did select row %i",path.row);
                   });
        ADD_METHOD(@selector(tableView:willSelectRowAtIndexPath:),
                   @protocol(UITableViewDelegate),
                   NO,
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
    
    
    UIView *tmpView = [[UIView allocAnonClass:^{
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
