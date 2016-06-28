//
//  QFLoginViewController.m
//  XMPPDemo
//
//  Created by iJeff on 15/3/27.
//  Copyright (c) 2015年 qianfeng. All rights reserved.
//

#import "QFLoginViewController.h"

//导入xmpp管理器
#import "QFXMPPManager.h"

@interface QFLoginViewController ()

//用户名输入框
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;

//密码输入框
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;



@end

@implementation QFLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    //给一个默认的用户名和密码
    _usernameTextField.text = @"view1@1000phone.net";
    _passwordTextField.text = @"123456";
    
}


#pragma  mark - 登录Action
- (IBAction)loginAction:(id)sender {
    
    
    [[QFXMPPManager shareManager] loginWithName:_usernameTextField.text andPassword:_passwordTextField.text result:^(BOOL success, NSError *error) {
        
        //登陆成功
        if ( success ) {
            NSLog(@" 登录成功了 ");
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@" 恭喜你！登录成功了！" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
        
        //登录失败
        else {
            NSLog(@" 登录失败了， error: %@", error);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@" 很遗憾！登录失败了！" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];

        }
        
    }];
    
    
}

#pragma  mark - 注册Action
- (IBAction)registerAction:(id)sender {
    
    [[QFXMPPManager shareManager] registerWithName:_usernameTextField.text andPassword:_passwordTextField.text result:^(BOOL success, NSError *error) {
        
        if (success) {
            NSLog(@"注册成功了");
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"注册成功，可以登录了！" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            
        }
        else {
            NSLog(@"注册失败了，error: %@", error);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"注册失败了，请换个账号注册！" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];

        }
        
    }];
    
}





@end
