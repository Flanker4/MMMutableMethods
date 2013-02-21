//
//  ORViewController.m
//  Runtime
//
//  Created by Boyko A.V. on 02.02.13.
//

#import "ORViewController.h"
#import "NSObject+MMAnonymousClass.h"
#import "UIOnClickListener.h"


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
   
    ds=[NSObject new:^{
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
    [self.tableView reloadData];
  
    UIButton *but= [UIButton buttonWithType:UIButtonTypeRoundedRect];
    but.frame=CGRectMake(0, 0, 50, 50);
    [self.view addSubview:but];
    
    [but addTarget:self
            action:@selector(onClick:)
  forControlEvents:UIControlEventTouchUpInside];
    
    
    but= [UIButton buttonWithType:UIButtonTypeRoundedRect];
    but.frame=CGRectMake(50, 0, 50, 50);
    [self.view addSubview:but];
    

    [but addTarget:[[UIOnClickListener new] overrideMethod:@selector(onClick:) blockImp:^void(id obj,id sender){
        
        UIViewController * vc = [[UIViewController alloc] init];
        
        
        [vc overrideMethod:@selector(viewWillAppear:) blockImp:^void(UIViewController* selfVC){
                selfVC.view.backgroundColor=[UIColor redColor];
                UIButton *but= [UIButton buttonWithType:UIButtonTypeRoundedRect];
                but.frame=CGRectMake(0, 0, 50, 50);
                [selfVC.view addSubview:but];
                

                __block UIOnClickListener *listener =[UIOnClickListener new:^{
                    OVERRIDE(@selector(onClick:), ^void(id selfObj,UIButton* sender){
                        [sender removeTarget:listener action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
                        [listener release];
                        listener=nil;
                        [self dismissViewControllerAnimated:YES completion:^{}];
                    });
                }];
                [but addTarget:listener
                        action:@selector(onClick:)
              forControlEvents:UIControlEventTouchUpInside];
            
            
        }];
       
        vc.modalPresentationStyle=UIModalPresentationFullScreen;
        [self presentViewController:vc animated:YES completion:^{}];
        [vc release];

    }]
            action:@selector(onClick:)
  forControlEvents:UIControlEventTouchUpInside];
    
    
    
    

}
-(void)viewDidAppear:(BOOL)animated{
        return;

}
-(IBAction)onClick:(id)sender{
    UIViewController * vc = [[UIViewController alloc] init];
    
    [vc view];
    vc.view.backgroundColor=[UIColor greenColor];
        
    UIButton *but= [UIButton buttonWithType:UIButtonTypeRoundedRect];
    but.frame=CGRectMake(0, 0, 50, 50);
    [vc.view addSubview:but];
    [but addTarget:self
            action:@selector(onClose:)
      forControlEvents:UIControlEventTouchUpInside];
    
    vc.modalPresentationStyle=UIModalPresentationFullScreen;
    
    [self presentViewController:vc animated:YES completion:^{}];
    [vc release];

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
