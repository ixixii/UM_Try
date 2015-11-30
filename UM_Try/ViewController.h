//
//  ViewController.h
//  UM_Try
//
//  Created by 肖利 on 15/11/17.
//  Copyright (c) 2015年 肖利. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *xib_field_msg;
- (IBAction)switchUser:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *xib_field_appID;
- (IBAction)picBtnClicked:(id)sender;

- (IBAction)playAMR:(id)sender;
- (IBAction)cameraBtnClicked:(id)sender;

- (IBAction)startRecordBtncliked:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;

- (IBAction)stopRecordBtnClicked:(id)sender;


@property (weak, nonatomic) IBOutlet UITextField *xib_field_targetUser;
@property (weak, nonatomic) IBOutlet UITextField *loginUserField;
@property (nonatomic,weak) IBOutlet UILabel *xib_msg_label;
- (IBAction)sendTextBtnClicked:(id)sender;

@property (nonatomic,weak) IBOutlet UIButton *xib_sendText_Btn;
- (IBAction)loginBtnClicked:(id)sender;

@end

