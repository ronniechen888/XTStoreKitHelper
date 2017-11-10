//
//  XTViewController.m
//  XTStoreKitHelper
//
//  Created by ronniechen888 on 10/29/2017.
//  Copyright (c) 2017 ronniechen888. All rights reserved.
//

#import "XTViewController.h"
#import "XTStoreKitHelper.h"

@interface XTViewController ()

@end

@implementation XTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	[[XTStoreKitHelper sharedStoreHelper] setProductIdentifiers:@[@"com.product.basket001"]];
	[[XTStoreKitHelper sharedStoreHelper] validateProductsReceiveResponse:^(NSArray<SKProduct *> *products, NSArray<NSString *> *invalidProductIdentifiers) {
		NSLog(@"111");
	} receiveFinish:^{
		
	} receiveFail:^(NSError *error) {
		
	}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
