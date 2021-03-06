//
//  ECDeskDelegate.h
//  CCPiPhoneSDK
//
//  Created by jiazy on 15/5/18.
//  Copyright (c) 2015年 ronglian. All rights reserved.
//


#import "ECDelegateBase.h"
#import "ECMessage.h"

/**
 * 该代理接收客服消息
 */
@protocol ECDeskDelegate <ECDelegateBase>

@optional
/**
 @brief 客服消息
 @param message 消息
 */
-(void)onReceiveDeskMessage:(ECMessage*)message;

@end