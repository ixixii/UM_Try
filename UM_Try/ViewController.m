//
//  ViewController.m
//  UM_Try
//
//  Created by 肖利 on 15/11/17.
//  Copyright (c) 2015年 肖利. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "SGMsgDBAccess.h"
#include "DeviceDelegateHelper.h"
#import <MobileCoreServices/MobileCoreServices.h>




#import <AssetsLibrary/ALAssetsLibrary.h>
#import <AssetsLibrary/ALAssetRepresentation.h>

#import "CommonTools.h"


#import "UIImageView+WebCache.h"

@interface ViewController ()<ECProgressDelegate,UIImagePickerControllerDelegate>
{
    ECMessage *_msg_arm;
    
//    BOOL _isReadDeleteMessage;
    
}

// 会话ID
@property (nonatomic, strong) NSString* sessionId;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageChanged:) name:KNOTIFICATION_onMesssageChanged object:nil];
    

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(message_img_mp4_downloaded:) name:@"noti_img_or_mp4_download_finished" object:nil];
    
    
    
    

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"点击了屏幕");
    [self logout];
}
#pragma mark - 登录
- (void)login_userName:(NSString *)userName
{
    ECLoginInfo * loginInfo = [[ECLoginInfo alloc] init];
    loginInfo.username = userName;//用户登录app的用户id即可。
    loginInfo.appKey = kApp_id;
    loginInfo.appToken = kApp_token;
    loginInfo.authType = LoginAuthType_NormalAuth;
    loginInfo.mode = LoginMode_InputPassword;
    
    ECDevice *device = [ECDevice sharedInstance];
    // 5.1.7都是生产环境
    // NSInteger res = [device SwitchServerEvn:YES];
    // NSLog(@"%ld",res);
    [[ECDevice sharedInstance] login:loginInfo completion:^(ECError *error){
        if (error.errorCode == ECErrorType_NoError) {
            //登录成功
            NSLog(@"登录成功");
            _xib_msg_label.text = @"登录成功";
            
#warning 设置代理
            [ECDevice sharedInstance].delegate = [DeviceDelegateHelper sharedInstance];
            
            // 建库和表
            [[SGMsgDBAccess sharedInstance]openDatabaseWithUserName:userName];
        }else{
            //登录失败
            NSLog(@"登录失败");
            _xib_msg_label.text = @"登录失败";
        }
    }];
}


#pragma mark - 登出
- (void)logout
{
    [[ECDevice sharedInstance] logout:^(ECError *error) {
        //登出结果
        if (error.errorCode == ECErrorType_NoError) {
            NSLog(@"登出成功");
            _xib_msg_label.text = @"登出成功";
        }else{
            _xib_msg_label.text = [NSString stringWithFormat:@"登出失败：%@",[error errorDescription]];
            NSLog(@"登出失败：%@",[error errorDescription]);
        }
    }];
}

#pragma mark - 发送文本
- (void)sendTextMsg_from:(NSString *)from to:(NSString *)to msg:(NSString *)msg
{
    //发送图片
    /*
     ECImageMessageBody *messageBody = [[ECImageMessageBody alloc] initWithFile:@"图片文件本地绝对路径"
     displayName:@"文件名称"];
     */
    
    //发送文件
    /*
     ECFileMessageBody *messageBody = [[ECFileMessageBody alloc] initWithFile:@"文件本地绝对路径"
     displayName:@"文件名称"];
     */
    
    
    //发送文本
    ECTextMessageBody *messageBody = [[ECTextMessageBody alloc] initWithText:[NSString stringWithFormat:@"%@你好，我是%@,我给你发了消息:%@",to,from,msg]];
    ECMessage *message = [[ECMessage alloc] initWithReceiver:to body:messageBody];
    
    //如果需要跨应用发送消息，需通过appkey+英文井号+用户帐号的方式拼接，发送录音、发送群组消息等与此方式一致。
    //例如：appkey=20150314000000110000000000000010
//    帐号ID=john
//    传入帐号=20150314000000110000000000000010#john
//    ECMessage *message = [[ECMessage alloc] initWithReceiver:@"appkey#John的账号Id" body:messageBody];
    
#warning 取本地时间
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval tmp =[date timeIntervalSince1970]*1000;
    message.timestamp = [NSString stringWithFormat:@"%lld", (long long)tmp];
    
    [[ECDevice sharedInstance].messageManager sendMessage:message progress:nil completion:^(ECError *error,
                                                                                            ECMessage *amessage) {
        
        if (error.errorCode == ECErrorType_NoError) {
            //发送成功
            _xib_msg_label.text = @"消息发送成功";
            NSLog(@"txt消息发送成功 NoError");
            
            
            
        }else if(error.errorCode == ECErrorType_Have_Forbid || error.errorCode == ECErrorType_File_Have_Forbid)
        {
            _xib_msg_label.text = @"您已被群组禁言";
            //您已被群组禁言
        }else{
            //发送失败
            _xib_msg_label.text = [NSString stringWithFormat:@"txt消息发送失败:  %@------%ld",[error errorDescription],(long)[error errorCode]];
            NSLog(@"txt消息发送失败：%@ ---%ld",[error errorDescription],(long)[error errorCode]);
        }
    }];
}



#pragma mark - 按钮点击
- (IBAction)sendTextBtnClicked:(id)sender {
    
    NSString *to = _xib_field_targetUser.text;
    if (_xib_field_appID.text.length > 0) {
        to = [NSString stringWithFormat:@"%@#%@",_xib_field_appID.text,_xib_field_targetUser.text];
        NSLog(@"接收者:%@",to);
    }
    [self sendTextMsg_from:_loginUserField.text to:to msg:_xib_field_msg.text];
}






-(void)handleMessage:(ECMessage*)message
{
    //如果是跨应用消息，from为appkey+英文井号+用户帐号。
    //例如：appkey=20150314000000110000000000000010
//    帐号ID=john
//    发送者=20150314000000110000000000000010#john
//NSLog:(@"收到%@的消息,属于%@会话", message.from, message.sessionId);
    
    switch(message.messageBody.messageBodyType){
        case MessageBodyType_Text:{
            ECTextMessageBody *msgBody = (ECTextMessageBody *)message.messageBody;
            NSLog(@"收到的是文本消息------%@,msgBody.text");
            _xib_msg_label.text = [NSString stringWithFormat:@"from:%@,sessonID:%@,content:%@",message.from,message.sessionId,msgBody.text];
            
            break;
        }
        case MessageBodyType_Voice:{
            ECVoiceMessageBody *msgBody = (ECVoiceMessageBody *)message.messageBody;
            NSLog(@"音频文件remote路径------%@",msgBody. remotePath);
            _xib_msg_label.text = [NSString stringWithFormat:@"音频文件remote路径------%@",msgBody.remotePath];
            
            
            // 收到,就开始下载
            [self abstract_downAMR:message];
            
            
            
            break;
        }
            
        case MessageBodyType_Video:{
            ECVideoMessageBody *msgBody = (ECVideoMessageBody *)message.messageBody;
            NSLog(@"视频文件remote路径------%@",msgBody. remotePath);
            
            _xib_msg_label.text = [NSString stringWithFormat:@"视频文件remote路径------%@",msgBody.remotePath];
            
            break;
        }
            
        case MessageBodyType_Image:{
            ECImageMessageBody *msgBody = (ECImageMessageBody *)message.messageBody;
            NSLog(@"图片文件remote路径------%@",msgBody. remotePath);
            NSLog(@"缩略图片文件remote路径------%@",msgBody. thumbnailRemotePath);
            
            _xib_msg_label.text = [NSString stringWithFormat:@"图片文件remote路径------%@",msgBody.remotePath];
            
            
            break;
        }
            
        case MessageBodyType_File:{
            ECFileMessageBody *msgBody = (ECFileMessageBody *)message.messageBody;
            NSLog(@"文件remote路径------%@",msgBody. remotePath);
            break;
        }
        default:
            break;
    }
}



- (void)abstract_downAMR:(ECMessage*)message
{
    [self downloadMediaMessage:message andCompletion:nil];
    
}



-(void)downloadMediaMessage:(ECMessage*)message andCompletion:(void(^)(ECError *error, ECMessage* message))completion{
    
    ECFileMessageBody *mediaBody = (ECFileMessageBody*)message.messageBody;
    mediaBody.localPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:mediaBody.displayName];
    
    NSLog(@"\r\n\r\n------->:即将下载到本地localPath__%@",mediaBody.localPath);
    
    
    
    NSLog(@"\r\n\r\n------->:开始下载MediaMessage");
    
    [[ECDevice sharedInstance].messageManager downloadMediaMessage:message progress:self completion:^(ECError *error, ECMessage *message) {
        if (error.errorCode == ECErrorType_NoError) {
            
            
            NSLog(@"\r\n\r\n------->:downloadMediaMessage_finished");
            
            
            
        } else {
            
        }
        _msg_arm = message;
        if (completion != nil) {
            completion(error, message);
        }
        
        
        NSLog(@"\r\n\r\n------->:发通知:KNOTIFICATION_DownloadMessageCompletion");
        
        
    _xib_msg_label.text = @"下载AMR完成,点击播放";
//        [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_DownloadMessageCompletion object:nil userInfo:@{KErrorKey:error, KMessageKey:message}];
        
    }];
}



- (void)messageChanged:(NSNotification *)noti
{
    
    
    NSLog(@"\r\n\r\n------->:收到通知:onMesssageChanged");
    ECMessage *message = (ECMessage*)noti.object;
//    if (![message.sessionId isEqualToString:self.sessionId]) {
//        return;
//    }
    
    
    [self handleMessage:message];
}

#pragma mark 录音
//开始录音
-(void)startRecord{
    static int seedNum = 0;
    if(seedNum >= 1000)
        seedNum = 0;
    seedNum++;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
    NSString *file = [NSString stringWithFormat:@"tmp%@%03d.amr", currentDateStr, seedNum];
    
    _xib_msg_label.text = [NSString stringWithFormat:@""];
    ECVoiceMessageBody * messageBody = [[ECVoiceMessageBody alloc] initWithFile:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:file] displayName:file];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[ECDevice sharedInstance].messageManager startVoiceRecording:messageBody error:^(ECError *error,
                                                                                      ECVoiceMessageBody *messageBody) {
        if (error.errorCode == ECErrorType_RecordTimeOut) {
            //录音超时，立即发送；应用也可以选择不发送
        }
    }];
}


//停止录音
-(void)stopRecord {
    [[ECDevice sharedInstance].messageManager stopVoiceRecording:^(ECError *error, ECVoiceMessageBody *messageBody) {
        if (error.errorCode == ECErrorType_NoError) {
            ECMessage *message = [[ECMessage alloc] initWithReceiver:_xib_field_targetUser.text body:messageBody];
            NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
            NSTimeInterval tmp =[date timeIntervalSince1970]*1000;
            message.timestamp = [NSString stringWithFormat:@"%lld", (long long)tmp];
            [[ECDevice sharedInstance].messageManager sendMessage:message progress:self
                                                       completion:^(ECError *error, ECMessage *amessage) {
                                                           if (error.errorCode == ECErrorType_NoError) {
                                                               //发送成功
                                                               _xib_msg_label.text = @"录音停止_发送_成功";
                                                               NSLog(@"录音停止_发送_成功");
                                                               
                                                           }else if(error.errorCode == ECErrorType_Have_Forbid || error.errorCode ==
                                                                    ECErrorType_File_Have_Forbid){
                                                               //您已被群组禁言
                                                           }else{
                                                               //发送失败
                                                               _xib_msg_label.text =[NSString stringWithFormat: @"录音停止_发送_失败:%@--%ld",[error errorDescription],(long)error.errorCode];
                                                               
                                                               NSLog(@"录音停止_发送_失败：%@",[NSString stringWithFormat: @"录音停止_发送_失败:%@--%ld",[error errorDescription],(long)error.errorCode]);
                                                           }
                                                       }];
        } else if  (error.errorCode == ECErrorType_RecordTimeTooShort) {
            //录音时间过短
            _xib_msg_label.text = @"录音time_short";
            NSLog(@"录音time_short");
        }
    }];
}

#pragma mark - 点击事件
- (IBAction)loginBtnClicked:(id)sender {
    [self login_userName:_loginUserField.text];
}
- (IBAction)switchUser:(id)sender {
    
    NSString *tmpStr = _loginUserField.text;
    _loginUserField.text = _xib_field_targetUser.text;
    _xib_field_targetUser.text = tmpStr;
    
}

#pragma mark - 播放AMR
- (IBAction)playAMR:(id)sender {
    NSLog(@"准备播放AMR");
    ECMessage *message = _msg_arm;
    ECVoiceMessageBody* mediaBody = (ECVoiceMessageBody*)message.messageBody;
    if (mediaBody.localPath.length>0 && [[NSFileManager defaultManager] fileExistsAtPath:mediaBody.localPath]) {
        
        NSLog(@"本地已存在ARM,播放就是了");
        [self playVoiceMessage:message];
    }
    
    
}




-(void)playVoiceMessage:(ECMessage*)message {
    
   
    
    
    
    
        
        if (0) {
            NSLog(@"耳机播放");
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        } else {
            NSLog(@"扬声器播放");
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        }
        
        NSLog(@" playVoiceMessage 开始播放AMR");
        [[ECDevice sharedInstance].messageManager playVoiceMessage:(ECVoiceMessageBody*)message.messageBody completion:^(ECError *error) {
            NSLog(@"AMR播放完成");
            _xib_msg_label.text = @"AMR播放完成";
        }];
        
  
}




- (IBAction)startRecordBtncliked:(id)sender {
    [self startRecord];
}

- (IBAction)stopRecordBtnClicked:(id)sender {
    [self stopRecord];
}


#pragma mark - 必须实现代理,不然报消息回调失败
/**
 @brief 设置进度
 @discussion 用户需实现此接口用以支持进度显示
 @param progress 值域为0到1.0的浮点数
 @param message  某一条消息的progress
 @result
 */
- (void)setProgress:(float)progress forMessage:(ECMessage *)message{
    
    // 消息发送的回调
    NSLog(@"...........>>>>>>消息发送的回调: DeviceChatHelper setprogress %f,messageId=%@,from=%@,to=%@,session=%@",progress,message.messageId,message.from,message.to,message.sessionId);
}

#pragma mark - 图片
- (IBAction)picBtnClicked:(id)sender
{
//    isReadDeleteMessage = NO;
    // 弹出照片选择
    [self popTypeOfImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)popTypeOfImagePicker:(UIImagePickerControllerSourceType)sourceType {
    
    [self.view endEditing:YES];
    
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = sourceType;
    imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self presentViewController:imagePicker animated:YES completion:NULL];
}


#pragma mark - uiimage picker delegate

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    DLog(@"mediaType :%@",mediaType);
    if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        DLog(@"准备发送视频");
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        [picker dismissViewControllerAnimated:YES completion:nil];
        
        // we will convert it to mp4 format
        NSURL *mp4 = [self convertToMp4:videoURL];
        NSFileManager *fileman = [NSFileManager defaultManager];
        if ([fileman fileExistsAtPath:videoURL.path]) {
            NSError *error = nil;
            [fileman removeItemAtURL:videoURL error:&error];
            if (error) {
                NSLog(@"failed to remove file, error:%@.", error);
            }
        }
        
        NSString *mp4Path = [mp4 relativePath];
        ECVideoMessageBody *mediaBody = [[ECVideoMessageBody alloc] initWithFile:mp4Path displayName:mp4Path.lastPathComponent];

        
        [self sendMediaMessage:mediaBody to:_xib_field_targetUser.text];
        
    } else {
        //
        DLog(@"准备发送图片");
        UIImage *orgImage = info[UIImagePickerControllerOriginalImage];
        [picker dismissViewControllerAnimated:YES completion:nil];
        
        NSURL *imageURL = [info valueForKey:UIImagePickerControllerReferenceURL];
        NSString* ext = imageURL.pathExtension.lowercaseString;
        
        if ([ext isEqualToString:@"gif"]) {
            DLog(@"这个是gif");
            [self saveGifToDocument:imageURL];
        } else {
            NSString *imagePath = [self saveToDocument:orgImage];
            ECImageMessageBody *mediaBody = [[ECImageMessageBody alloc] initWithFile:imagePath displayName:imagePath.lastPathComponent];
            DLog(@"这个是图片路径:%@",imagePath);
            
            [self sendMediaMessage:mediaBody to:_xib_field_targetUser.text];

        }
    }
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
}





#pragma mark - 工具方法
- (UIImage *)fixOrientation:(UIImage *)aImage {
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform     // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,CGImageGetBitsPerComponent(aImage.CGImage), 0,CGImageGetColorSpace(aImage.CGImage),CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
        default:              CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);              break;
    }       // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

#define DefaultThumImageHigth 90.0f
#define DefaultPressImageHigth 960.0f

-(void)saveGifToDocument:(NSURL *)srcUrl {
    
    ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *asset) {
        
        if (asset != nil) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            Byte *imageBuffer = (Byte*)malloc((unsigned long)rep.size);
            NSUInteger bufferSize = [rep getBytes:imageBuffer fromOffset:0.0 length:(unsigned long)rep.size error:nil];
            NSData *imageData = [NSData dataWithBytesNoCopy:imageBuffer length:bufferSize freeWhenDone:YES];
            
            NSDateFormatter* formater = [[NSDateFormatter alloc] init];
            [formater setDateFormat:@"yyyyMMddHHmmssSSS"];
            NSString* fileName =[NSString stringWithFormat:@"%@.gif", [formater stringFromDate:[NSDate date]]];
            NSString* filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName];
            
            [imageData writeToFile:filePath atomically:YES];
            
            ECImageMessageBody *mediaBody = [[ECImageMessageBody alloc] initWithFile:filePath displayName:filePath.lastPathComponent];

            
            [self sendMediaMessage:mediaBody to:_xib_field_targetUser.text];
        } else {
            DLog(@"进入了else");
        }
    };
    
    ALAssetsLibrary* assetLibrary = [[ALAssetsLibrary alloc] init];
    [assetLibrary assetForURL:srcUrl
                  resultBlock:resultBlock
                 failureBlock:^(NSError *error){
                 }];
}

-(NSString*)saveToDocument:(UIImage*)image {
    UIImage* fixImage = [self fixOrientation:image];
    
    NSDateFormatter* formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyyMMddHHmmssSSS"];
    NSString* fileName =[NSString stringWithFormat:@"%@.jpg", [formater stringFromDate:[NSDate date]]];
    
    NSString* filePath=[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName];
    
    //图片按0.5的质量压缩－》转换为NSData
    CGSize pressSize = CGSizeMake((DefaultPressImageHigth/fixImage.size.height) * fixImage.size.width, DefaultPressImageHigth);
    UIImage * pressImage = [CommonTools compressImage:fixImage withSize:pressSize];
    NSData *imageData = UIImageJPEGRepresentation(pressImage, 0.5);
    [imageData writeToFile:filePath atomically:YES];
    
    CGSize thumsize = CGSizeMake((DefaultThumImageHigth/fixImage.size.height) * fixImage.size.width, DefaultThumImageHigth);
    UIImage * thumImage = [CommonTools compressImage:fixImage withSize:thumsize];
    NSData * photo = UIImageJPEGRepresentation(thumImage, 0.5);
    NSString * thumfilePath = [NSString stringWithFormat:@"%@.jpg_thum", filePath];
    [photo writeToFile:thumfilePath atomically:YES];
    
    return filePath;
    
}
#pragma mark  保存音视频文件
- (NSURL *)convertToMp4:(NSURL *)movUrl {
    
    NSURL *mp4Url = nil;
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:movUrl options:nil];
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    if ([compatiblePresets containsObject:AVAssetExportPreset640x480]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset
                                                                               presetName:AVAssetExportPreset640x480];
        
        NSDateFormatter* formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyyMMddHHmmssSSS"];
        NSString* fileName = [NSString stringWithFormat:@"%@.mp4", [formater stringFromDate:[NSDate date]]];
        NSString* path = [NSString stringWithFormat:@"file:///private%@",[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName]];
        mp4Url = [NSURL URLWithString:path];
        
        exportSession.outputURL = mp4Url;
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputFileType = AVFileTypeMPEG4;
        dispatch_semaphore_t wait = dispatch_semaphore_create(0l);
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed: {
                    NSLog(@"failed, error:%@.", exportSession.error);
                } break;
                case AVAssetExportSessionStatusCancelled: {
                    NSLog(@"cancelled.");
                } break;
                case AVAssetExportSessionStatusCompleted: {
                    NSLog(@"completed.");
                } break;
                default: {
                    NSLog(@"others.");
                } break;
            }
            dispatch_semaphore_signal(wait);
        }];
        
        long timeout = dispatch_semaphore_wait(wait, DISPATCH_TIME_FOREVER);
        if (timeout) {
            NSLog(@"timeout.");
        }
        
        if (wait) {
            wait = nil;
        }
    }
    
    return mp4Url;
}


#pragma mark - 发送消息操作




#pragma mark - 发送图片
-(ECMessage*)sendMediaMessage:(ECFileMessageBody*)mediaBody to:(NSString*)to
{
    DLog(@"sendMediaMessage : to :");
    ECMessage *message = [[ECMessage alloc] initWithReceiver:to body:mediaBody];
    message.userData = @"";
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval tmp =[date timeIntervalSince1970]*1000;
    
#warning 入库前设置本地时间，以本地时间排序和以本地时间戳获取本地数据库缓存数据
    message.timestamp = [NSString stringWithFormat:@"%lld", (long long)tmp];
    
    
    [[ECDevice sharedInstance].messageManager sendMessage:message progress:self completion:^(ECError *error, ECMessage *amessage) {
        
        if (error.errorCode == ECErrorType_NoError) {
            DLog(@"发送图片成功");
            //                [self playSendMsgSound];
        } else if (error.errorCode == ECErrorType_Have_Forbid || error.errorCode == ECErrorType_File_Have_Forbid) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"您已被禁言" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
        } else if (error.errorCode == ECErrorType_ContentTooLong) {
            DLog(@"发送图片失败:内容太长");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:error.errorDescription delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
        }else{
            DLog(@"发送图片失败:%ld",error.errorCode);
            //发送图片失败:170002
        }
        
        //            [[IMMsgDBAccess sharedInstance] updateState:message.messageState ofMessageId:message.messageId andSession:message.sessionId];
        //            [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_SendMessageCompletion object:nil userInfo:@{KErrorKey:error, KMessageKey:amessage}];
    }];
    
    
    
    NSLog(@"\r\n\r\n------->sendMessage:to:      DeviceChatHelper sendMediaMessage messageid=%@",message.messageId);
    
    //    [[DeviceDBHelper sharedInstance] addNewMessage:message andSessionId:message.sessionId];
    
    return message;
}

- (void)message_img_mp4_downloaded:(NSNotification *)noti
{
    _xib_msg_label.text = @"下载完成,即将显示";
    ECMessage *msg = [noti.userInfo objectForKey:@"message"];
    ECImageMessageBody *mediaBody = (ECImageMessageBody*)msg.messageBody;
    
    switch (msg.messageBody.messageBodyType) {
        case MessageBodyType_Image:
        {
            //显示 图片
            [_imgView sd_setImageWithURL:[NSURL URLWithString:mediaBody.thumbnailRemotePath] completed:nil];
        }
            break;
            
        
        case MessageBodyType_Video:
        {
            //显示 图片
            [_imgView sd_setImageWithURL:[NSURL URLWithString:mediaBody.thumbnailRemotePath] completed:nil];
        }
            break;
        
            
        default:
            break;
    }
}

#pragma mark - 相机 
- (IBAction)cameraBtnClicked:(id)sender
{
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
#if 0
    //只照相
    imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
#else
    //支持视频功能
    imagePicker.mediaTypes = @[(NSString *)kUTTypeImage,(NSString *)kUTTypeMovie];
    imagePicker.videoMaximumDuration = 30;
#endif
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        //判断相机是否能够使用
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if(status == AVAuthorizationStatusAuthorized) {
            // authorized
            [self presentViewController:imagePicker animated:YES completion:NULL];
        } else if(status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied){
            // restricted
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在“设置-隐私-相机”选项中允许访问你的相机" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
            });
        } else if(status == AVAuthorizationStatusNotDetermined){
            // not determined
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if(granted){
                    [self presentViewController:imagePicker animated:YES completion:NULL];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在“设置-隐私-相机”选项中允许访问你的相机" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
                    });
                }
            }];
        }
    }
}
@end

