//
//  XTViewController.m
//  XTStoreKitHelper
//
//  Created by ronniechen888 on 10/29/2017.
//  Copyright (c) 2017 ronniechen888. All rights reserved.
//

#import "XTViewController.h"
#import <XTStoreKitHelper/XTStoreKitHelper.h>
#import "AvePurchaseButton.h"
#import "XTDownloadViewController.h"

@interface XTViewController ()
@property (nonatomic,strong) NSMutableArray *productArray;
@end

@implementation XTViewController
{
	NSMutableIndexSet* _busyIndexes;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	_busyIndexes = [NSMutableIndexSet new];
	self.productArray = [NSMutableArray array];
	
	self.tableView.rowHeight = 54;
	
	self.tableView.layoutMargins = UIEdgeInsetsZero;
	self.tableView.separatorInset = UIEdgeInsetsZero;
	
	[[XTStoreKitHelper sharedStoreHelper] setProductIdentifiers:@[@"com.product.basket001",@"com.product.basket002",@"com.product.basket003",@"com.product.basket004",@"com.product.basket005"]];
	[[XTStoreKitHelper sharedStoreHelper] validateProductsReceiveResponse:^(NSArray<SKProduct *> *products, NSArray<NSString *> *invalidProductIdentifiers) {
		[_productArray addObjectsFromArray:products];
		[self.tableView reloadData];
	} receiveFinish:^{
		
	} receiveFail:^(NSError *error) {
		
	}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)purchaseButtonTapped:(AvePurchaseButton*)button
{
	NSIndexPath* indexPath = [self.tableView indexPathForCell:(UITableViewCell*)button.superview];
	NSInteger index = indexPath.row;
	
	// handle taps on the purchase button by
	switch(button.buttonState)
	{
		case AvePurchaseButtonStateNormal:
			// progress -> confirmation
			[button setButtonState:AvePurchaseButtonStateConfirmation animated:YES];
			break;
			
		case AvePurchaseButtonStateConfirmation:{
			// confirmation -> "purchase" progress
			[_busyIndexes addIndex:index];
			[button setButtonState:AvePurchaseButtonStateProgress animated:YES];
			SKProduct *product = [_productArray objectAtIndex:indexPath.row];
			[[XTStoreKitHelper sharedStoreHelper] setPayProcessPurchasing:^(SKPaymentTransaction *transaction) {
				NSLog(@"purchasing");
			} deferred:^(SKPaymentTransaction *transaction) {
				NSLog(@"deferred");
			} failed:^(SKPaymentTransaction *transaction) {
				NSLog(@"failed");
				[button setButtonState:AvePurchaseButtonStateNormal animated:NO];
				[button setButtonState:AvePurchaseButtonStateConfirmation animated:YES];
			} purchased:^(CheckReceiptResult result, SKPaymentTransaction *transaction) {
				if (result == CheckReceiptResultYes) {
				
					[button setButtonState:AvePurchaseButtonStateNormal animated:NO];
					[button setButtonState:AvePurchaseButtonStateConfirmation animated:YES];
					button.confirmationTitle = @"已购买";
					
			
					if ([transaction.downloads count] > 0) {
						XTDownloadViewController *downloadViewController = [[XTDownloadViewController alloc] initWithNibName:@"XTDownloadViewController" bundle:nil];
						downloadViewController.transaction = transaction;
						[self.navigationController pushViewController:downloadViewController animated:YES];
					}else{
						[[XTStoreKitHelper sharedStoreHelper] finishTransaction:transaction];
					}
				}else if(result == CheckReceiptResultNo){
					NSLog(@"222");
					
					UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"警告" message:@"凭据有异常！" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
					[alertView show];
					
					[[XTStoreKitHelper sharedStoreHelper] finishTransaction:transaction];
				}else{
					NSLog(@"333");
					
					[[XTStoreKitHelper sharedStoreHelper] finishTransaction:transaction];
				}
			} restored:^(SKPaymentTransaction *transaction) {
				NSLog(@"444");
			}];
			[[XTStoreKitHelper sharedStoreHelper] buyProduct:product quantity:1 userAccount:nil startProcess:nil canNotPay:nil checkReceiptType:CheckReceiptTypeAppStore];
		}
			break;
			
		case AvePurchaseButtonStateProgress:
			// progress -> back to normal
			[_busyIndexes removeIndex:index];
			[button setButtonState:AvePurchaseButtonStateNormal animated:YES];
			break;
	}
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_productArray count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString* const CellIdentifier = @"Cell";
	
	UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if(nil == cell)
	{
		// create  a cell with some nice defaults
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.layoutMargins = UIEdgeInsetsZero;
		cell.separatorInset = UIEdgeInsetsZero;
		cell.detailTextLabel.textColor = [UIColor grayColor];
		
		// add a buttons as an accessory and let it respond to touches
		AvePurchaseButton* button = [[AvePurchaseButton alloc] initWithFrame:CGRectZero];
		[button addTarget:self action:@selector(purchaseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		cell.accessoryView = button;
	}
	
	SKProduct *product = [_productArray objectAtIndex:indexPath.row];
	// configure the cell
	cell.textLabel.text = product.localizedTitle.length > 0?product.localizedTitle:@"续期订阅服务";
	cell.detailTextLabel.text = product.localizedDescription;
	
	// configure the purchase button in state normal
	AvePurchaseButton* button = (AvePurchaseButton*)cell.accessoryView;
	button.buttonState = AvePurchaseButtonStateNormal;
	button.normalTitle = [XTStoreKitHelper currencyPriceWithProduct:product];
	button.confirmationTitle = @"BUY";
	[button sizeToFit];
	
	if ([[XTStoreKitHelper sharedStoreHelper] checkReceiptIsIncludeProduct:product]) {
		button.buttonState = AvePurchaseButtonStateConfirmation;
		button.confirmationTitle = @"已购买";
	}
	
	// if the item at this indexPath is being "busy" with purchasing, update the purchase
	// button's state to reflect so.
	if([_busyIndexes containsIndex:indexPath.row] == YES)
	{
		button.buttonState = AvePurchaseButtonStateProgress;
	}
	
	
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
}


@end
