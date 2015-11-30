//
//  IMMsgDBAccess.h
//  AppCanPlugin
//
//  Created by 肖利 on 15/11/24.
//  Copyright (c) 2015年 zywx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGMsgDBAccess : NSObject
+(instancetype )sharedInstance;

- (void)openDatabaseWithUserName:(NSString*)userName;
@end
