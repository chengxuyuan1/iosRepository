//
//  QFChatViewController.m
//  XMPPDemo
//
//  Created by iJeff on 15/3/27.
//  Copyright (c) 2015年 qianfeng. All rights reserved.
//

#import "QFChatViewController.h"

//导入chatModel
#import "QFChatModel.h"

//导入QFXMPPManager.h
#import "QFXMPPManager.h"

@interface QFChatViewController ()
<UITableViewDataSource, UITableViewDelegate>
{
    //数据
    NSMutableArray *datas;
    
}
//输入框
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;

//tableView
@property (weak, nonatomic) IBOutlet UITableView *myTableView;




@end

@implementation QFChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        datas = [[NSMutableArray alloc] init];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [[QFXMPPManager shareManager] getMessage:^(QFChatModel *model) {
        
        [datas addObject:model];
        
        [_myTableView reloadData];
        
    }];
    
    
    //tableView
    _myTableView.delegate = self;
    _myTableView.dataSource = self;
    
}

#pragma  mark - tableView 代理方法
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  datas.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if ( !cell ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    QFChatModel *model = datas[indexPath.row];
    
    cell.textLabel.text = model.content;
    
    return cell;
}


#pragma  mark - 发送信息Action
- (IBAction)sendAction:(id)sender {
    
    [[QFXMPPManager shareManager] sendMessage:_inputTextField.text to:_name result:^(BOOL success) {
        
        if ( success ) {
            NSLog(@"发送信息成功");
        }
        else {
            NSLog(@"发送信息失败");
        }
        
    }];
    
    
}







@end
