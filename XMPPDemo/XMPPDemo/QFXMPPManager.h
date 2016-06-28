//
//  QFXMPPManager.h
//  XMPPDemo
//
//  Created by iJeff on 15/3/27.
//  Copyright (c) 2015年 qianfeng. All rights reserved.
//

#import <Foundation/Foundation.h>


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






@end
