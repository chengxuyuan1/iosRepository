//
//  QFFriendListViewController.m
//  XMPPDemo
//
//  Created by iJeff on 15/3/27.
//  Copyright (c) 2015年 qianfeng. All rights reserved.
//

#import "QFFriendListViewController.h"

//导入QFXMPPManager.h
#import "QFXMPPManager.h"

//导入用户model
#import "QFUserModel.h"

//导入聊天室的头文件
#import "QFChatViewController.h"

@interface QFFriendListViewController ()
<UITableViewDataSource, UITableViewDelegate>
{
    //保存好友数据
    NSMutableArray *datas;
    
}
//输入框
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;

//tableView
@property (weak, nonatomic) IBOutlet UITableView *myTableView;


@end

@implementation QFFriendListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"我的好友";
        
        //初始化
        datas = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //获取好友
    [[QFXMPPManager shareManager] getAllFriends:^(NSArray *friends) {
        NSLog(@"friends.count: %d", friends.count);
        
        [datas removeAllObjects];
        
        [datas addObjectsFromArray:friends];
        
        [_myTableView reloadData];
        
    }];
    
    //tableView
    _myTableView.delegate = self;
    _myTableView.dataSource = self;
    
}

#pragma  mark - tableView 回调方法
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return datas.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if ( !cell ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    //
    QFUserModel *model = datas[indexPath.row];
    
    cell.textLabel.text = model.name;
    
    //如果是在线状态，显示黑色的文字
    if ( [model.status isEqualToString:@"available"] ) {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    //如果不在线，则显示灰色的文字
    else {
        cell.textLabel.textColor = [UIColor grayColor];
    }
    
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QFUserModel *model = datas[indexPath.row];
    
    //进入聊天室
    QFChatViewController *chatVC = [[QFChatViewController alloc] init];
    chatVC.name = model.name;
    [self.navigationController pushViewController:chatVC animated:YES];
}



#pragma  mark - 添加好友Action
- (IBAction)addFriendAction:(id)sender {
    
    [[QFXMPPManager shareManager] addFriend:_inputTextField.text];
    
}







@end
