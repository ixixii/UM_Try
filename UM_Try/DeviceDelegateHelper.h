//
//  DeviceDelegateHelper.h
//  UM_Try
//
//  Created by 肖利 on 15/11/17.
//  Copyright (c) 2015年 肖利. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ECDeviceHeaders.h"

#import "DeviceDelegateHelper.h"

#import "AppDelegate.h"




#define KNOTIFICATION_onConnected       @"KNOTIFICATION_onConnected"

#define KNOTIFICATION_onNetworkChanged    @"KNOTIFICATION_onNetworkChanged"

#define KNOTIFICATION_onSystemEvent    @"KNOTIFICATION_onSystemEvent"

#define KNOTIFICATION_onMesssageChanged    @"KNOTIFICATION_onMesssageChanged"

#define KNOTIFICATION_onRecordingAmplitude    @"KNOTIFICATION_onRecordingAmplitude"

#define KNOTIFICATION_onReceivedGroupNotice    @"KNOTIFICATION_onReceivedGroupNotice"

#define KNOTIFICATION_haveHistoryMessage @"KNOTIFICATION_haveHistoryMessage"
#define KNOTIFICATION_HistoryMessageCompletion @"KNOTIFICATION_HistoryMessageCompletion"

#define KNOTIFICATION_needInputName @"KNOTIFICATION_needInputName"


@interface DeviceDelegateHelper : NSObject<ECDeviceDelegate>

/**
 
 *@brief 获取DeviceDelegateHelper单例句柄
 
 */

+(DeviceDelegateHelper*)sharedInstance;

//代理类.m文件中需要实现ECDeviceDelegate的回调函数，代码示例如下:



//如需使用IM功能，需实现ECChatDelegate类的回调函数。

//如需使用实时音视频功能，需实现ECVoIPCallDelegate类的回调函数。

//如需使用音视频会议功能，需实现ECMeetingDelegate类的回调函数。
@end