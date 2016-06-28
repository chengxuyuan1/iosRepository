//
//  QFXMPPManager.m
//  XMPPDemo
//
//  Created by iJeff on 15/3/27.
//  Copyright (c) 2015年 qianfeng. All rights reserved.
//

#import "QFXMPPManager.h"

//导入xmppFramework
#import "XMPPFramework.h"

//导入用户model
#import "QFUserModel.h"


@interface QFXMPPManager ()
<XMPPStreamDelegate>
{
    
    XMPPStream *_xmppStream; //xmpp流
    XMPPRoster *_xmppRoster; //xmpp花名册
    XMPPRosterCoreDataStorage *_xmppStorage; //xmpp花名册存储类
    XMPPReconnect *_xmppReconnect; //xmpp的重连机制类
    
    
    //保存用户数据
    QFUserModel *userModel;
    
    //判断是否在注册（注册/登录）
    BOOL isRegister;
    
    //注册结果的block
    void (^registerResultBlock)(BOOL success, NSError *error);
    
    //登陆结果的block
    void (^loginResultBlock)(BOOL success, NSError *error);
    
}

@end

@implementation QFXMPPManager


//单例
+ (QFXMPPManager *)shareManager
{
    static QFXMPPManager *shareInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[QFXMPPManager alloc] init];
    });
    return shareInstance;
}

//init
- (id)init
{
    self = [super init];
    if (self) {
        
        // 1、初始化xmpp流
        _xmppStream = [[XMPPStream alloc] init];
        
        // 设置主机
        [_xmppStream setHostName:@"1000phone.net"];
        
        // 设置端口
        [_xmppStream setHostPort:5222];
        
        // 设置代理
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        
        // 2、初始化断线重连机制
        _xmppReconnect = [[XMPPReconnect alloc] init];
        [_xmppReconnect activate:_xmppStream];
        
        
        // 3、初始化花名册
        //初始化花名册存储对象
        _xmppStorage = [[XMPPRosterCoreDataStorage alloc] init];
        
        //初始化花名册
        _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppStorage];
        [_xmppRoster activate:_xmppStream];
        
        
        //初始化用户model
        userModel = [[QFUserModel alloc] init];
        
    }
    return self;
}

#pragma  mark - 用户注册
// 先注册用户名， 然后再注册密码
- (void)registerWithName:(NSString *)name andPassword:(NSString *)password result:(void (^)(BOOL, NSError *))resultBlock
{
    registerResultBlock = [resultBlock copy];
    
    //正在注册
    isRegister = YES;
    
    
    //保存用户名和密码
    userModel.name = name;
    userModel.password = password;
    
    
    //将name转换成jid
    XMPPJID *jid = [XMPPJID jidWithString:name];
    [_xmppStream setMyJID:jid];
    
    //如果已经连接了，则先断开连接
    if ([_xmppStream isConnected] || [_xmppStream isConnecting] ) {
        [_xmppStream disconnect];
    }
    
    //连接服务器
    NSError *error = nil;
    BOOL ret = [_xmppStream connectWithTimeout:-1 error:&error];
    if ( !ret ) {
        NSLog(@"连接失败");
        
        if ( registerResultBlock ) {
            registerResultBlock (NO, error);
        }
    }
}

#pragma  mark - 用户登录
- (void)loginWithName:(NSString *)name
          andPassword:(NSString *)password
               result:( void(^)(BOOL success, NSError *error) )resultBlock
{
    loginResultBlock = [resultBlock copy];
    
    //正在登录(不是正在注册)
    isRegister = NO;
    
    //保存用户名和密码
    userModel.name = name;
    userModel.password = password;
    
    //把name转换成jid
    XMPPJID *jid = [XMPPJID jidWithString:name];
    _xmppStream.myJID = jid;
    
    
    //先断开旧连接
    if ( [_xmppStream isConnected] || [_xmppStream isConnecting] ) {
        [_xmppStream disconnect];
    }
    
    //开始连接服务器
    NSError *error = nil;
    BOOL ret = [_xmppStream connectWithTimeout:-1 error:&error];
    if ( !ret ) {
        NSLog(@"连接失败");
        if ( loginResultBlock ) {
            loginResultBlock (NO, error);
        }
    }
}


#pragma  mark - 已经连接服务器成功
-(void)xmppStreamDidConnect:(XMPPStream *)sender
{
    
    if ( isRegister ) {
        
        //注册密码
        [_xmppStream registerWithPassword:userModel.password error:nil];
    }
    
    else {
        
        //登陆，验证密码
        [_xmppStream authenticateWithPassword:userModel.password error:nil];
    }
}

#pragma  mark - 注册成功
-(void)xmppStreamDidRegister:(XMPPStream *)sender
{
    NSLog(@"注册成功");
    if ( registerResultBlock ) {
        registerResultBlock (YES, nil);
    }
}

#pragma mark -- 注册失败
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
    NSLog(@"注册失败");
    
    NSError *myError = [NSError errorWithDomain:error.description code:-1 userInfo:nil];
    if ( registerResultBlock ) {
        registerResultBlock (NO, myError);
    }
}

#pragma  mark - 登录成功
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@" 登录成功 ");
    
    if ( loginResultBlock ) {
        loginResultBlock(YES, nil);
    }
    
    // 申请上线
    [self online];
    
    // 请求获取好友列表
    [self requestFriends];
    
}

#pragma  mark -- 登陆失败
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    NSLog(@" 登录失败 ");
    
    NSError *myError = [NSError errorWithDomain:error.description code:-1 userInfo:nil];
    if ( loginResultBlock ) {
        loginResultBlock (NO, myError);
    }
}



#pragma  mark - 申请上线
- (void)online
{
    // 创建一个xml对象，并发送给服务器
    XMPPPresence *presence = [XMPPPresence presence];
    //"available"
//    NSLog(@"presence: %@", presence);
    
    [_xmppStream sendElement:presence];
}

#pragma  mark - 订阅事件
/*
 available -- 发送available：申请上线；(默认) 接收到available：某好友上线了
 unavailable -- 发送unavailable：申请下线； 接收到unavailable： 某好友下线了
 subscribe -- 发送subscribe：请求加对方为好友； 接收到subscribe：别人加我好友
 unsubscribe -- 发送unsubscribe：删除好友； 接收到unsubscribe：对方已将我删除
 subscribed -- 发送subscribed：同意对方的加好友请求； 接收到subscribed：对方已经同意我的加好友请求
 unsubscribed -- 发送unsubscribed：拒绝对方的加好友请求； 接收到unsubscribed：对方拒绝我的加好友请求
 error -- 当前状态packet有错误
*/

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    
    NSLog(@"presence：%@", presence);
    
    /*
     <presence xmlns="jabber:client" from="view1@1000phone.net/c0314c94" to="view1@1000phone.net/c0314c94"/>
     
     <presence xmlns="jabber:client" from="nie@1000phone.net/7909126" to="nie@1000phone.net/7909126"/>
     <presence xmlns="jabber:client" from="nie8@1000phone.net/a319b938" to="nie@1000phone.net/7909126"/>
     
     <presence xmlns="jabber:client" type="unavailable" from="nie8@1000phone.net/a319b938" to="nie@1000phone.net"/>
     */
    
    
}

#pragma  mark - 向服务器请求获取好友列表
-(void)requestFriends
{
    //
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    
    [iq addAttributeWithName:@"type" stringValue:@"get"];
    [iq addChild:query];
    
//    NSLog(@" iq :%@", iq);
    
    /*
     <iq type="get">
        <query xmlns="jabber:iq:roster"/>
     </iq>
     */
    
    //发送xml数据，请求获取好友列表
    [_xmppStream sendElement:iq];
    
}

#pragma  mark - 获取到所有好友的信息
-(BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@" iq :%@", iq);
    
    /*
     <iq xmlns="jabber:client" type="result" id="0C78E1D9-8D9A-4520-A03A-410A90E7FC40" to="nie@1000phone.net/4cf995b5">
      <query xmlns="jabber:iq:roster">
       <item jid="nie8@1000phone.net" subscription="both"/>
       <item jid="nie3@1000phone.net" subscription="both"/>
       <item jid="ijeff@1000phone.net" subscription="both"/>
       <item jid="nie2@1000phone.net" subscription="both"/>
      </query>
     </iq>
     */
    
    return YES;
}











@end
