//
//  XTDownloadViewController.m
//  XTStoreKitHelper_Example
//
//  Created by Ronnie Chen on 2017/11/14.
//  Copyright © 2017年 ronniechen888. All rights reserved.
//

#import "XTDownloadViewController.h"

@interface XTDownloadViewController ()

@end

@implementation XTDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

	
	[[XTStoreKitHelper sharedStoreHelper] setDownloadStateWaiting:^(SKDownload *download) {
		self.statusLabel.text = [NSString stringWithFormat:@"Waiting / Remain %f seconds",download.timeRemaining];
	} active:^(SKDownload *download) {
		self.statusLabel.text = [NSString stringWithFormat:@"Downloading / Remain %f seconds",download.timeRemaining > 0 ? download.timeRemaining:100];
		self.progressView.progress = download.progress;
	} paused:^(SKDownload *download) {
		self.statusLabel.text = [NSString stringWithFormat:@"Download Paused"];
	} finished:^(SKDownload *download) {
		self.statusLabel.text = [NSString stringWithFormat:@"Download Finished"];
		self.progressView.progress = 1.0;
		
		NSArray *fileArray = [[XTStoreKitHelper sharedStoreHelper] getDownloadFilePathArrayFromDownload:download];
		UIImage *image = [UIImage imageWithContentsOfFile: [fileArray firstObject]];
		self.topView.image = image;
		
		[[XTStoreKitHelper sharedStoreHelper] finishTransaction:_transaction];
	} failed:^(SKDownload *download) {
		self.statusLabel.text = [NSString stringWithFormat:@"Download Failed"];
		
		NSArray *fileArray = [[XTStoreKitHelper sharedStoreHelper] getDownloadFilePathArrayFromDownload:download];
		UIImage *image = [UIImage imageWithContentsOfFile: [fileArray firstObject]];
		self.topView.image = image;
		
//		[[XTStoreKitHelper sharedStoreHelper] finishTransaction:_transaction];
	} cancelled:^(SKDownload *download) {
		self.statusLabel.text = [NSString stringWithFormat:@"Download Cancelled"];
		
		[[XTStoreKitHelper sharedStoreHelper] finishTransaction:_transaction];
	}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)start{
	[[XTStoreKitHelper sharedStoreHelper] startDownloads:_transaction.downloads];
}

-(void)pauseAndResume{
	[[XTStoreKitHelper sharedStoreHelper] pauseDownloads:_transaction.downloads];
}

-(void)cancel{
	[[XTStoreKitHelper sharedStoreHelper] cancelDownloads:_transaction.downloads];
}

@end
