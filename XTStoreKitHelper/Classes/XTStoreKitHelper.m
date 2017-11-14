//
//  XTStoreKitHelper.m
//  FBSnapshotTestCase
//
//  Created by Ronnie Chen on 2017/10/29.
//

#import "XTStoreKitHelper.h"
#import <CommonCrypto/CommonCrypto.h>
#import "RMAppReceipt.h"

NSString *const RMStoreErrorDomain = @"net.robotmedia.store";
NSInteger const RMStoreErrorCodeUnableToCompleteVerification = 200;

@interface XTStoreKitHelper()

@property (nonatomic,copy) NSArray *productIdArray;
@property (nonatomic,strong) SKProductsRequest *request;
@property (nonatomic,assign) CheckReceiptType checkType;
@property (nonatomic,strong) SKReceiptRefreshRequest *receiptRefreshRequest;

///validate process block
@property (nonatomic,copy) void (^validatResponse)(NSArray<SKProduct *> *products,NSArray<NSString *> *invalidProductIdentifiers);
@property (nonatomic,copy) void (^validatDidFinish)(void);
@property (nonatomic,copy) void (^validatDidFail)(NSError *);

///pay process block
@property (nonatomic,copy) void (^purchasingProcess)(SKPaymentTransaction *transaction);
@property (nonatomic,copy) void (^deferredProcess)(SKPaymentTransaction *transaction); 
@property (nonatomic,copy) void (^failedProcess)(SKPaymentTransaction *transaction); 
@property (nonatomic,copy) void (^purchasedProcess)(CheckReceiptResult result,SKPaymentTransaction *transaction);
@property (nonatomic,copy) void (^restoredProcess)(SKPaymentTransaction *transaction);

///download state handle
@property (nonatomic,copy) void (^downloadStateActiveHandle)(SKDownload *download);
@property (nonatomic,copy) void (^downloadStateCancelledHandle)(SKDownload *download);
@property (nonatomic,copy) void (^downloadStateFailedHandle)(SKDownload *download);
@property (nonatomic,copy) void (^downloadStateFinishedHandle)(SKDownload *download);
@property (nonatomic,copy) void (^downloadStatePausedHandle)(SKDownload *download);
@property (nonatomic,copy) void (^downloadStateWaitingHandle)(SKDownload *download);

///properties
@property (nonatomic,strong) NSString *bundleIdentifier;
@property (nonatomic,strong) NSString *bundleVersion;

///Handle Receipt Refresh Request
@property (nonatomic,copy) void (^refreshSuccessHandle)(void);
@property (nonatomic,copy) void (^refreshFailedHandle)(void);

@end

@implementation XTStoreKitHelper

+(instancetype)sharedStoreHelper
{
	static XTStoreKitHelper *storeHelper = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		storeHelper = [[XTStoreKitHelper alloc] init];
	});
	
	return storeHelper;
}

-(void)addTransactionObserver
{
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

-(void)removeTransactionObserver
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

-(void)setProductIdentifiers:(NSArray *)productIdentifiers
{
	if(self.productIdArray)
	{
		_productIdArray = nil;
	}
	
	_productIdArray = productIdentifiers;
}

-(void)validateProductsReceiveResponse:(void (^)(NSArray<SKProduct *> *products,NSArray<NSString *> *invalidProductIdentifiers))validateResponse receiveFinish:(void (^)(void))validatDidFinish receiveFail:(void (^)(NSError *))validateDidFail
{
	self.validatResponse = validateResponse;
	self.validatDidFinish = validatDidFinish;
	self.validatDidFail = validateDidFail;
	
	SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:self.productIdArray]];
	
	self.request = productsRequest;
	
	productsRequest.delegate = self;
	
	[productsRequest start];
}

-(void)stopValidateProcess
{
	[self.request cancel];
}

+(NSString *)currencyPriceWithProduct:(SKProduct *)product
{
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setLocale:product.priceLocale];
	NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];
	
	return formattedPrice;
}

+(BOOL)canMakePayment{
	return [SKPaymentQueue canMakePayments];
}

-(void)finishTransaction:(SKPaymentTransaction *)transaction{
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	if(self.validatResponse){
		self.validatResponse(response.products, response.invalidProductIdentifiers);
	}
	NSLog(@"Product request receive response");
}

- (void)requestDidFinish:(SKRequest *)request{
	if (request == self.request) {
		if(self.validatDidFinish){
			self.validatDidFinish();
		}
		NSLog(@"Product request finished");
	}else if(request == self.receiptRefreshRequest){
		if (self.refreshSuccessHandle) {
			self.refreshSuccessHandle();
		}
	}
	
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{

	if (request == self.request) {
		if(self.validatDidFail)
		{
			self.validatDidFail(error);
		}
		NSLog(@"Product request failed");
	}else if(request == self.receiptRefreshRequest){
		if (self.refreshFailedHandle) {
			self.refreshFailedHandle();
		}
	}
}

#pragma mark - Begin Buy Process
-(void)setPayProcessPurchasing:(void (^)(SKPaymentTransaction *))purchasingProcess deferred:(void (^)(SKPaymentTransaction *))deferredProcess failed:(void (^)(SKPaymentTransaction *))failedProcess purchased:(void (^)(CheckReceiptResult, SKPaymentTransaction *))purchasedProcess restored:(void (^)(SKPaymentTransaction *))restoredProcess{
	self.purchasingProcess = purchasingProcess;
	self.deferredProcess = deferredProcess;
	self.failedProcess = failedProcess;
	self.purchasedProcess = purchasedProcess;
	self.restoredProcess = restoredProcess;
}

- (void)buyProduct:(SKProduct *)product quantity:(NSInteger)quantity userAccount:(NSString *)userAccount startProcess:(void (^)(void))startProcessBlock canNotPay:(void (^)(void))canNotPayBlock checkReceiptType:(CheckReceiptType)checkType
{
	if ([XTStoreKitHelper canMakePayment]) {
		if (startProcessBlock) {
			startProcessBlock();
		}
		SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
		payment.quantity = quantity;
		if (userAccount.length > 0) {
			NSString *accountHash = [self hashedValueForAccountName:userAccount];
			if (accountHash.length > 0) {
				payment.applicationUsername = accountHash;
			}
		}
		self.checkType = checkType;
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	}else{
		if (canNotPayBlock) {
			canNotPayBlock();
		}
	}
	
}

- (NSString *)hashedValueForAccountName:(NSString*)userAccountName
{
	const int HASH_SIZE = 32;
	unsigned char hashedChars[HASH_SIZE];
	const char *accountName = [userAccountName UTF8String];
	size_t accountNameLen = strlen(accountName);
	// Confirm that the length of the user name is small enough
	// to be recast when calling the hash function.
	if (accountNameLen > UINT32_MAX) {
		NSLog(@"Account name too long to hash: %@", userAccountName);
		return nil; 
	}
	CC_SHA256(accountName, (CC_LONG)accountNameLen, hashedChars);
	// Convert the array of bytes into a string showing its hex representation.
	NSMutableString *userAccountHash = [[NSMutableString alloc] init];
	for (int i = 0; i < HASH_SIZE; i++) {
		// Add a dash every four bytes, for readability.
		if (i != 0 && i%4 == 0) {
			[userAccountHash appendString:@"-"];
		}
		[userAccountHash appendFormat:@"%02x", hashedChars[i]];
	}
	return userAccountHash;
}


-(void)saveReceiptToCloudOrUserDefault
{
#if USE_ICLOUD_STORAGE
	NSUbiquitousKeyValueStore *storage = [NSUbiquitousKeyValueStore defaultStore];
#else
	NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
#endif
	NSData *newReceipt = [RMAppReceipt bundleReceiptData];
	NSArray *savedReceipts = [storage arrayForKey:@"receipts"];
	if (!savedReceipts) {
		// Storing the first receipt
		[storage setObject:@[newReceipt] forKey:@"receipts"];
	} else {
		// Adding another receipt
		NSArray *updatedReceipts = [savedReceipts arrayByAddingObject:newReceipt];
		[storage setObject:updatedReceipts forKey:@"receipts"];
	}
	[storage synchronize];
}

-(BOOL)checkReceiptIsIncludeProduct:(SKProduct *)product{
	RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
	
	return [receipt containsInAppPurchaseOfProductIdentifier:product.productIdentifier];
}


#pragma mark - Verify Receipt By Local

- (NSString*)bundleIdentifier
{
	if (!_bundleIdentifier)
	{
		return [NSBundle mainBundle].bundleIdentifier;
	}
	return _bundleIdentifier;
}

- (NSString*)bundleVersion
{
	if (!_bundleVersion)
	{
#if TARGET_OS_IPHONE
		return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
#else
		return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#endif
	}
	return _bundleVersion;
}

- (BOOL)verifyAppReceipt:(RMAppReceipt*)receipt
{
	if (!receipt) return NO;
	
	if (![receipt.bundleIdentifier isEqualToString:self.bundleIdentifier]) return NO;
	
	if (![receipt.appVersion isEqualToString:self.bundleVersion]) return NO;
	
	if (![receipt verifyReceiptHash]) return NO;
	
	return YES;
}

- (BOOL)localVerifyTransaction:(SKPaymentTransaction*)transaction
				inReceipt:(RMAppReceipt*)receipt
				  success:(void (^)(void))successBlock
				  failure:(void (^)(NSError *error))failureBlock
{
	const BOOL receiptVerified = [self verifyAppReceipt:receipt];
	if (!receiptVerified)
	{
		[self failWithBlock:failureBlock message:NSLocalizedStringFromTable(@"The app receipt failed verification", @"RMStore", nil)];
		return NO;
	}
	SKPayment *payment = transaction.payment;
	const BOOL transactionVerified = [receipt containsInAppPurchaseOfProductIdentifier:payment.productIdentifier];
	if (!transactionVerified)
	{
		[self failWithBlock:failureBlock message:NSLocalizedStringFromTable(@"The app receipt does not contain the given product", @"RMStore", nil)];
		return NO;
	}
	if (successBlock)
	{
		successBlock();
	}
	return YES;
}

- (void)failWithBlock:(void (^)(NSError *error))failureBlock message:(NSString*)message
{
	NSError *error = [NSError errorWithDomain:RMStoreErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : message}];
	[self failWithBlock:failureBlock error:error];
}

- (void)failWithBlock:(void (^)(NSError *error))failureBlock error:(NSError*)error
{
	if (failureBlock)
	{
		failureBlock(error);
	}
}

#pragma mark - Verify Receipt By Remote App Store

- (void)appstoreVerifyReceiptSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock
{    
	NSURL *recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];  
	NSData *receipt = [NSData dataWithContentsOfURL:recepitURL];  
	if (receipt == nil)
	{
		if (failureBlock != nil)
		{
			NSError *error = [NSError errorWithDomain:RMStoreErrorDomain code:0 userInfo:nil];
			failureBlock(error);
		}
		return;
	}
	static NSString *receiptDataKey = @"receipt-data";
	NSDictionary *jsonReceipt = @{receiptDataKey : [receipt base64EncodedStringWithOptions:0]};
	
	NSError *error;
	NSData *requestData = [NSJSONSerialization dataWithJSONObject:jsonReceipt options:0 error:&error];
	if (!requestData)
	{
		
		if (failureBlock != nil)
		{
			failureBlock(error);
		}
		return;
	}
	
	static NSString *productionURL = @"https://buy.itunes.apple.com/verifyReceipt";
	
	[self verifyRequestData:requestData url:productionURL success:successBlock failure:failureBlock];
}

- (void)verifyRequestData:(NSData*)requestData
					  url:(NSString*)urlString
				  success:(void (^)(void))successBlock
				  failure:(void (^)(NSError *error))failureBlock
{
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	request.HTTPBody = requestData;
	static NSString *requestMethod = @"POST";
	request.HTTPMethod = requestMethod;
	
	dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//		NSError *error;
//		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
		NSURLSession *session = [NSURLSession sharedSession];
		NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (!data)
				{
					
					NSError *wrapperError = [NSError errorWithDomain:RMStoreErrorDomain code:RMStoreErrorCodeUnableToCompleteVerification userInfo:@{NSUnderlyingErrorKey : error, NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"Connection to Apple failed. Check the underlying error for more info.", @"RMStore", @"Error description")}];
					if (failureBlock != nil)
					{
						failureBlock(wrapperError);
					}
					return;
				}
				NSError *jsonError;
				NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
				if (!responseJSON)
				{
					NSLog(@"Failed To Parse Server Response");
					if (failureBlock != nil)
					{
						failureBlock(jsonError);
					}
				}
				
				static NSString *statusKey = @"status";
				NSInteger statusCode = [responseJSON[statusKey] integerValue];
				
				static NSInteger successCode = 0;
				static NSInteger sandboxCode = 21007;
				if (statusCode == successCode)
				{
					if (successBlock != nil)
					{
						successBlock();
					}
				}
				else if (statusCode == sandboxCode)
				{
					NSLog(@"Verifying Sandbox Receipt");
					// From: https://developer.apple.com/library/ios/#technotes/tn2259/_index.html
					// See also: http://stackoverflow.com/questions/9677193/ios-storekit-can-i-detect-when-im-in-the-sandbox
					// Always verify your receipt first with the production URL; proceed to verify with the sandbox URL if you receive a 21007 status code. Following this approach ensures that you do not have to switch between URLs while your application is being tested or reviewed in the sandbox or is live in the App Store.
					
					static NSString *sandboxURL = @"https://sandbox.itunes.apple.com/verifyReceipt";
					[self verifyRequestData:requestData url:sandboxURL success:successBlock failure:failureBlock];
				}
				else
				{
					NSLog(@"Verification Failed With Code %ld", (long)statusCode);
					NSError *serverError = [NSError errorWithDomain:RMStoreErrorDomain code:statusCode userInfo:nil];
					if (failureBlock != nil)
					{
						failureBlock(serverError);
					}
				}
			});
		}];
		
		[task resume];
	});
}

#pragma mark - Refresh Receipt Request
-(void)refreshReceiptOnSuccess:(void (^)(void))successHandle failed:(void (^)(void))failedHandle
{
	self.refreshSuccessHandle = successHandle;
	self.refreshFailedHandle = failedHandle;
	self.receiptRefreshRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:@{}];
	self.receiptRefreshRequest.delegate = self;
	[self.receiptRefreshRequest start];
}

#pragma mark - Manage Host Content
-(void)setDownloadStateWaiting:(void (^)(SKDownload *))downloadStateWaiting active:(void (^)(SKDownload *))downloadStateActive paused:(void (^)(SKDownload *))downloadStatePaused finished:(void (^)(SKDownload *))downloadStateFinished failed:(void (^)(SKDownload *))downloadStateFailed cancelled:(void (^)(SKDownload *))downloadStateCancelled{
	self.downloadStateWaitingHandle = downloadStateWaiting;
	self.downloadStateActiveHandle = downloadStateActive;
	self.downloadStatePausedHandle = downloadStatePaused;
	self.downloadStateFinishedHandle = downloadStateFinished;
	self.downloadStateFailedHandle = downloadStateFailed;
	self.downloadStateCancelledHandle = downloadStateCancelled;
}

-(void)startDownloads:(NSArray<SKDownload *> *)downloads{
	[[SKPaymentQueue defaultQueue] startDownloads:downloads];
}

-(void)pauseDownloads:(NSArray<SKDownload *> *)downloads{
	[[SKPaymentQueue defaultQueue] pauseDownloads:downloads];
}

-(void)resumeDownloads:(NSArray<SKDownload *> *)downloads{
	[[SKPaymentQueue defaultQueue] resumeDownloads:downloads];
}

-(void)cancelDownloads:(NSArray<SKDownload *> *)downloads{
	[[SKPaymentQueue defaultQueue] cancelDownloads:downloads];
}

-(NSMutableArray<NSString *> *)getDownloadFilePathArrayFromDownload:(SKDownload *)download
{
	NSString *source = [download.contentURL relativePath];
	NSDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:[source stringByAppendingPathComponent:@"ContentInfo.plist"]];
	
	NSMutableArray<NSString *> *fileArray = [NSMutableArray<NSString *> array];
	
	if (![dict objectForKey:@"Files"])
	{
		return fileArray;
	}
	
	NSAssert([dict objectForKey:@"Files"], @"The Files property must be valid");
	
	for (NSString *file in (NSArray *)[dict objectForKey:@"Files"])
	{
		NSString *content = [[source stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:file];
		if ([[NSFileManager defaultManager] fileExistsAtPath:content]) {
			[fileArray addObject:content];
		}
	}
	
	return fileArray;
}

#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
	for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
				// Call the appropriate custom method for the transaction state.
			case SKPaymentTransactionStatePurchasing:
				if (self.purchasingProcess) {
					self.purchasingProcess(transaction);
				}
				break;
			case SKPaymentTransactionStateDeferred:
				if (self.deferredProcess) {
					self.deferredProcess(transaction);
				}
				break;
			case SKPaymentTransactionStateFailed:
				if (self.failedProcess) {
					self.failedProcess(transaction);
				}
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			case SKPaymentTransactionStatePurchased:
			{
				
				if (self.checkType == CheckReceiptTypeLocal) {
					///For security,we need to verify the receipt.
					[self localVerifyTransaction:transaction inReceipt:[RMAppReceipt bundleReceipt] success:^{
						[self saveReceiptToCloudOrUserDefault];
						if (self.purchasedProcess) {
							self.purchasedProcess(CheckReceiptResultYes,transaction);
						}
					} failure:^(NSError *error) {
						[self refreshReceiptOnSuccess:^{
							[self saveReceiptToCloudOrUserDefault];
							if (self.purchasedProcess) {
								self.purchasedProcess(CheckReceiptResultYes,transaction);
							}
						} failed:^{
							if (self.purchasedProcess) {
								self.purchasedProcess(CheckReceiptResultNo,transaction);
							}
						}];
						
					}];
				}else if (self.checkType == CheckReceiptTypeAppStore){
					[self appstoreVerifyReceiptSuccess:^{
						[self saveReceiptToCloudOrUserDefault];
						
						if (self.purchasedProcess) {
							self.purchasedProcess(CheckReceiptResultYes,transaction);
						}
					} failure:^(NSError *error) {
						[self refreshReceiptOnSuccess:^{
							[self saveReceiptToCloudOrUserDefault];
							if (self.purchasedProcess) {
								self.purchasedProcess(CheckReceiptResultYes,transaction);
							}
						} failed:^{
							if (self.purchasedProcess) {
								self.purchasedProcess(CheckReceiptResultNo,transaction);
							}
						}];
					}];
				}else{
					if (self.purchasedProcess) {
						self.purchasedProcess(CheckReceiptResultNoneCheck,transaction);
					}
			
				}
				
//				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
			}
				
				break;
			case SKPaymentTransactionStateRestored:
				
				if (self.restoredProcess) {
					self.restoredProcess(transaction);
				}
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			default:
				
				NSLog(@"Unexpected transaction state %@",
					  @(transaction.transactionState));
				break; 
		}
	}
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads
{
	for (SKDownload *download in downloads)
	{
		switch (download.downloadState)
		{
			case SKDownloadStateActive:
			{
				if (self.downloadStateActiveHandle) {
					self.downloadStateActiveHandle(download);
				}
				break;
			}
				
			case SKDownloadStateCancelled: 
			{ 
				if (self.downloadStateCancelledHandle) {
					self.downloadStateCancelledHandle(download);
				}
				break; 
			}
				
			case SKDownloadStateFailed:
			{
				if (self.downloadStateFailedHandle) {
					self.downloadStateFailedHandle(download);
				}
				break;
			}
				
			case SKDownloadStateFinished:
			{
				if (self.downloadStateFinishedHandle) {
					self.downloadStateFinishedHandle(download);
				}
				break;
			}
				
			case SKDownloadStatePaused:
			{
				if (self.downloadStatePausedHandle) {
					self.downloadStatePausedHandle(download);
				}
				break;
			}
				
			case SKDownloadStateWaiting:
			{
				if (self.downloadStateWaitingHandle) {
					self.downloadStateWaitingHandle(download);
				}
				break;
			}
		}
	}
}

@end
