//
//  XTDownloadViewController.h
//  XTStoreKitHelper_Example
//
//  Created by Ronnie Chen on 2017/11/14.
//  Copyright © 2017年 ronniechen888. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XTStoreKitHelper/XTStoreKitHelper.h>

@interface XTDownloadViewController : UIViewController

@property (nonatomic,strong) SKPaymentTransaction *transaction;

@property (nonatomic,weak) IBOutlet UIImageView *topView;
@property (nonatomic,weak) IBOutlet UIProgressView *progressView;
@property (nonatomic,weak) IBOutlet UILabel *statusLabel;

-(IBAction)start;

-(IBAction)pauseAndResume;

-(IBAction)cancel;

@end
