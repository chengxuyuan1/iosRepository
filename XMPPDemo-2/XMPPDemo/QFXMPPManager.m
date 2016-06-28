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
    
    //保存所有好友
    NSMutableArray *allFriends;
    
    //判断是否在注册（注册/登录）
    BOOL isRegister;
    
    //注册结果的block
    void (^registerResultBlock)(BOOL success, NSError *error);
    
    //登陆结果的block
    void (^loginResultBlock)(BOOL success, NSError *error);
    
    //获取好友结果的block
    void (^getFriendsResultBlock)(NSArray *friends);
    
    //发送信息结果的block
    void (^sendMessageResultBlock)(BOOL success);
    
    //接收信息结果的block
    void (^getMessageResultBlock)(QFChatModel *model);
    
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
        
        //初始化allFriends
        allFriends = [[NSMutableArray alloc] init];
        
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
    
//    NSLog(@"presence：%@", presence);
    
    /*
     <presence xmlns="jabber:client" from="view1@1000phone.net/c0314c94" to="view1@1000phone.net/c0314c94"/>
     
     <presence xmlns="jabber:client" from="nie@1000phone.net/7909126" to="nie@1000phone.net/7909126"/>
     <presence xmlns="jabber:client" from="nie8@1000phone.net/a319b938" to="nie@1000phone.net/7909126"/>
     
     <presence xmlns="jabber:client" type="unavailable" from="nie8@1000phone.net/a319b938" to="nie@1000phone.net"/>
     */
    
    NSString *from = [presence attributeStringValueForName:@"from"];
//    NSLog(@"from: %@", from);
    //nie@1000phone.net/67f1ed1a
    XMPPJID *fromJid = [XMPPJID jidWithString:from];
    
    NSString *friendStr = [NSString stringWithFormat:@"%@@%@", fromJid.user, fromJid.domain];
    XMPPJID *friendJid = [XMPPJID jidWithString:friendStr];
    
//    NSLog(@"friendStr: %@", friendStr);

    
    
    
    //好友状态
    NSString *type = [presence type];
    NSLog(@" === type :%@", type);

    NSString *status = @"available"; //默认是在线状态
    
    //如果有好友上线了
    if ( [type isEqualToString:@"available"] ) {
        NSLog(@"有好友上线了：%@ ", friendStr);
        status = @"available";
    }
    
    //有好友下线了
    else if ( [type isEqualToString:@"unavailable"] ){
        NSLog(@"有好友下线了：%@", friendStr);
        status = @"unavailable";
    }
    
    //有人请求添加我为好友
    else if ( [type isEqualToString:@"subscribe"] ) {
        
        NSLog(@" 有人要加我为好友，这个人是：%@", friendStr);
        //接受别人的加好友请求，并且请求添加对方为好友
        [_xmppRoster acceptPresenceSubscriptionRequestFrom:friendJid andAddToRoster:YES];
        
    }
    
    //更新所有好友的某一个好友的状态
    [self updateFriend:friendStr withNewStatus:status];
    
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
    
    
    
    //发送xml数据，请求获取好友列表
    [_xmppStream sendElement:iq];
    
}

#pragma  mark - 获取到所有好友的信息
-(BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
//    NSLog(@" iq :%@", iq);
    
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
    
    NSXMLElement *query = iq.childElement;
    //遍历query的所有子节点
    for (NSXMLElement *item in query.children) {
        NSString *name = [item attributeStringValueForName:@"jid"];
        NSLog(@"friend Name: %@", name);
        
        //添加好友到allFriends中
        [self addFriendWithName:name andStatus:@"unavailable"];
    }
    
    return YES;
}

#pragma  mark - 添加好友到allFriends中
- (void)addFriendWithName:(NSString *)name andStatus:(NSString *)status
{
    //遍历原本所有的好友
    for (QFUserModel *model in allFriends) {
        
        //如果存在相同名称的好友，不添加
        if ( [model.name isEqualToString:name] ) {
            NSLog(@" 已经存在该好友了 ，不添加了 ");
            return;
        }
    }
    
    //取得自己的名称
    NSString *myName = [NSString stringWithFormat:@"%@@%@", _xmppStream.myJID.user, _xmppStream.myJID.domain];
    
    if ( [name isEqualToString:myName] ) {
        NSLog(@" 是我自己，不添加 ");
        return;
    }
    
    //添加这个好友
    QFUserModel *model = [[QFUserModel alloc] init];
    model.name = name;
    model.status = status;
    
    [allFriends addObject:model];
    
//    NSLog(@"allFriends.count: %d", allFriends.count);
    
    //每添加一个好友，返回最新的allFriends
    if ( getFriendsResultBlock ) {
        getFriendsResultBlock(allFriends);
    }
    
}


#pragma mark - 更新所有好友的某一个好友的状态
- (void)updateFriend:(NSString *)name withNewStatus:(NSString *)newStatus
{
    for (QFUserModel *model in allFriends) {
        
        //判断是否已经存在该好友，存在则修改其状态
        if ( [model.name isEqualToString:name] ) {
            model.status = newStatus;
            
            //返回更新状态后的最新的allFriends
            if ( getFriendsResultBlock ) {
                getFriendsResultBlock(allFriends);
            }
            
            return;
        }
    }
    
    //添加该好友
    [self addFriendWithName:name andStatus:newStatus];
    
}

#pragma  mark - 获取好友
- (void)getAllFriends:( void(^)(NSArray *friends) )resultBlock
{
    getFriendsResultBlock = [resultBlock copy];
    
    //返回allFriends
    if ( getFriendsResultBlock ) {
        getFriendsResultBlock(allFriends);
    }
    
}

#pragma  mark - 添加好友
- (void)addFriend:(NSString *)name
{
    XMPPJID *jid = [XMPPJID jidWithString:name];
    
    //请求添加好友
    [_xmppRoster subscribePresenceToUser:jid];
}




#pragma  mark - 发送信息
- (void)sendMessage:(NSString *)content to:(NSString *)name result:( void(^)(BOOL success) )resultBlock
{
    sendMessageResultBlock = [resultBlock copy];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:content];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:name];
    [message addChild:body];
    
    NSLog(@"message: %@", message);
    
    /*
     <message type="chat" to="cpm@1000phone.net">
        <body>dfa </body>
     </message>
     */
    
    //发送信息
    [_xmppStream sendElement:message];
    
}

#pragma  mark -- 发送信息成功的回调方法
- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    if ( sendMessageResultBlock ) {
        sendMessageResultBlock(YES);
    }
}

#pragma  mark -- 发送信息失败
- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    if ( sendMessageResultBlock ) {
        sendMessageResultBlock(NO);
    }
}

#pragma  mark - 接收信息
- (void)getMessage:( void(^)(QFChatModel *model) )resultBlock
{
    getMessageResultBlock = [resultBlock copy];
}

-(void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    if ( [message isChatMessage] ) {
        
        if ([message isChatMessageWithBody]) {
            
            NSString *body = message.body;
            NSString *from = message.from.bare;
            NSString *to = message.to.bare;
            
            QFChatModel *model = [[QFChatModel alloc] init];
            model.content = body;
            model.from = from;
            model.to = to;
            
            if ( getMessageResultBlock ) {
                getMessageResultBlock(model);
            }
        }
        
    }
    
}









@end
