//
//  IMMsgDBAccess.m
//  AppCanPlugin
//
//  Created by 肖利 on 15/11/24.
//  Copyright (c) 2015年 zywx. All rights reserved.
//

#import "SGMsgDBAccess.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
// MD5加密用到
#import <CommonCrypto/CommonDigest.h>
@interface SGMsgDBAccess()
@property (nonatomic, strong) FMDatabase *dataBase;
@end
@implementation SGMsgDBAccess

+(instancetype)sharedInstance{
    static SGMsgDBAccess* imdbmanager;
    static dispatch_once_t imdbmanageronce;
    dispatch_once(&imdbmanageronce, ^{
        imdbmanager = [[SGMsgDBAccess alloc] init];
    });
    return imdbmanager;
}



- (void)openDatabaseWithUserName:(NSString*)userName {
    if (userName.length==0) {
        return;
    }
    
    //Documents:
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//
//    //username md5
//    const char *cStr = [userName UTF8String];
//    unsigned char result[16];
//    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
//    NSString* MD5 =  [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],result[8], result[9], result[10], result[11],result[12], result[13], result[14], result[15]];
//    
    //数据库文件夹
    NSString * documentsDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"database"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:documentsDirectory isDirectory:&isDir];
    if(!(isDirExist && isDir)) {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir) {
            NSLog(@"Create Database Directory Failed.");
        }
        NSLog(@"%@", documentsDirectory);
    }

    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:userName];
    
    
    
    // 构造 APPCAN里面的路径 dbPath=/var/mobile/Containers/Data/Application/647A9379-9DB0-402D-83F5-9A8FFD8CEBE5/Documents/database/uexDB
 
              
    
    
    
    
    if (self.dataBase) {
        [self.dataBase close];
        self.dataBase = nil;
    }
    
    self.dataBase = [FMDatabase databaseWithPath:dbPath];
    [self.dataBase open];
    
    
    // 创建成员表
    [self memberTableCreate];
    [self IMGroupIDTableCreate];
    [self IMGroupNoticeTableCreate];
    [self sessionTableCreate];
    [self IMTriggerCreate];
    

    
}



#pragma mark - 工具方法
// 判断指定表是否存在
- (BOOL)checkTableExist:(NSString *)tableName {
    BOOL result = NO;
    NSString* lowtableName = [tableName lowercaseString];
    
    FMResultSet *rs = [self.dataBase executeQuery:@"SELECT [sql] FROM sqlite_master WHERE [type] = 'table' AND lower(name) = ?", lowtableName];
    result = [rs next];
    [rs close];
    
    return result;
}

// 创建表
- (void) createTable:(NSString*)tableName sql:(NSString *)createSql {

    BOOL isExist = [self.dataBase tableExists:tableName];
    if (!isExist) {
        [self.dataBase executeUpdate:createSql];
    }
}


#pragma mark - 创建成员表
- (void)memberTableCreate{
    DLog(@"创建 userName 表");
    
    [self createTable:@"userName" sql:@"CREATE table userName (userid TEXT NOT NULL PRIMARY KEY UNIQUE ON CONFLICT REPLACE, nickName TEXT, sex INTEGER)"];
}

#pragma mark - 创建groupinfo2表
- (void)IMGroupIDTableCreate {
    
    DLog(@"创建 groupinfo2 表");
    
    [self createTable:@"im_groupinfo2" sql:@"CREATE table im_groupinfo2 (groupId TEXT NOT NULL PRIMARY KEY UNIQUE ON CONFLICT REPLACE, type INTEGER, groupname TEXT, isNotice bool); create unique index groupinfo_info_index2 on im_groupinfo2(groupId)"];
    BOOL isExist = [self.dataBase tableExists:@"im_groupinfo"];
    if (isExist) {
        [self.dataBase executeUpdate:@"INSERT INTO im_groupinfo2 SELECT *,YES FROM im_groupinfo"];
        [self.dataBase executeUpdate:@"DROP TABLE IF EXISTS im_groupinfo"];
        [self.dataBase executeUpdate:@"DROP INDEX IF EXISTS groupinfo_info_index"];
    }
}

#pragma mark - 创建groupNotice表
/*
 群组推送消息表
 字段	类型	约束	备注
 ID	int		自增
 groupId 	Varchar	32	群组id
 type 	int		消息类型
 admin 	Varchar	32	管理员
 member 	Varchar	32	成员
 declared 	Varchar	256	原因
 dateCreated 	Long		服务器的时间 毫秒
 confirm 	int		是否需要确认
 */
- (void)IMGroupNoticeTableCreate {
    
    DLog(@"创建 群组推送 groupnotice 表");
    
    [self createTable:@"im_groupnotice" sql:@"CREATE table im_groupnotice(ID INTEGER PRIMARY KEY AUTOINCREMENT,groupId varchar(32),groupName varchar(32),type INTEGER,admin varchar(32),member varchar(32),nickName varchar(32), declared varchar(32), dateCreated INTEGER, isRead INTEGER, confirm INTEGER, sender varchar(32))"];
    if (![self.dataBase columnExists:@"isDiscuss" inTableWithName:@"im_groupnotice"]) {
        [self.dataBase executeUpdate:@"alter table im_groupnotice add isDiscuss integer default 0"];
    }
}


#pragma mark - 创建session表
/*
 会话表
 字段	类型	约束	备注
 sessionId 	TEXT	会话id
 dateTime 	Long		显示的时间 毫秒
 type 	int		与消息表msgType一样
 text 	Varchar	2048	显示的内容
 unreadCount	int		未读消息数
 sumCount 	int		总消息数
 */

- (void)sessionTableCreate {
    
    DLog(@"创建 会话 session 表");
    
    [self createTable:@"session" sql:@"CREATE table session (sessionId TEXT NOT NULL PRIMARY KEY UNIQUE ON CONFLICT REPLACE, dateTime INTEGER,type INTEGER,text varchar(2048),unreadCount INTEGER,sumCount INTEGER,state INTEGER)"];
}

#pragma mark - 创建TRIGGER
- (void)IMTriggerCreate {
    DLog(@"创建  TRIGGER ");
    
    BOOL result = NO;
    FMResultSet *rs = [self.dataBase executeQuery:@"SELECT [sql] FROM sqlite_master WHERE [type] = 'trigger' AND lower(name) = ?", @"delete_obsolete_im"];
    result = [rs next];
    [rs close];
    if (result) {
        // 如果有触发器,则删除触发器 delete_obsolete_im
        [self.dataBase executeUpdate:@"DROP TRIGGER delete_obsolete_im"];
        [self.dataBase executeUpdate:@"DROP TRIGGER im_update_thread_on_insert"];
        [self.dataBase executeUpdate:@"DROP TRIGGER im_update_thread_on_update"];
    }
}
@end
