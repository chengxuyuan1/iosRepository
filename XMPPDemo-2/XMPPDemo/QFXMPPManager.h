//
//  QFXMPPManager.h
//  XMPPDemo
//
//  Created by iJeff on 15/3/27.
//  Copyright (c) 2015年 qianfeng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QFChatModel.h"

@interface QFXMPPManager : NSObject

//单例
+ (QFXMPPManager *)shareManager;


#pragma  mark - 用户注册
- (void)registerWithName:(NSString *)name
             andPassword:(NSString *)password
                  result:( void(^)(BOOL success, NSError *error) )resultBlock;

#pragma  mark - 用户登录
- (void)loginWithName:(NSString *)name
          andPassword:(NSString *)password
               result:( void(^)(BOOL success, NSError *error) )resultBlock;


#pragma  mark - 获取好友
- (void)getAllFriends:( void(^)(NSArray *friends) )resultBlock;


#pragma  mark - 添加好友
- (void)addFriend:(NSString *)name;


#pragma  mark - 发送信息
- (void)sendMessage:(NSString *)content to:(NSString *)name result:( void(^)(BOOL success) )resultBlock;

#pragma  mark - 接收信息
- (void)getMessage:( void(^)(QFChatModel *model) )resultBlock;




@end
