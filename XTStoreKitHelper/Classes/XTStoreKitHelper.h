//
//  XTStoreKitHelper.h
//  FBSnapshotTestCase
//
//  Created by Ronnie Chen on 2017/10/29.
//

#import <Foundation/Foundation.h>
#import <Storekit/StoreKit.h>

typedef enum : NSUInteger {
	CheckReceiptTypeLocal,
	CheckReceiptTypeAppStore,
	CheckReceiptTypeCustom,
} CheckReceiptType;

typedef enum : NSUInteger {
	CheckReceiptResultYes,
	CheckReceiptResultNo,
	CheckReceiptResultNoneCheck,
} CheckReceiptResult;

@interface XTStoreKitHelper : NSObject<SKProductsRequestDelegate,SKPaymentTransactionObserver>

+ (instancetype)sharedStoreHelper;

+ (BOOL)canMakePayment;

+ (NSString *)currencyPriceWithProduct:(SKProduct *)product;

- (void)addTransactionObserver;

- (void)removeTransactionObserver;

- (void)setProductIdentifiers:(NSArray *)productIdentifiers;

- (void)validateProductsReceiveResponse:(void (^)(NSArray<SKProduct *> *products,NSArray<NSString *> *invalidProductIdentifiers))validateResponse
						 receiveFinish:(void (^)(void))validatDidFinish
						   receiveFail:(void (^)(NSError *))validateDidFail;

- (void)stopValidateProcess;

- (void)setPayProcessPurchasing:(void (^)(SKPaymentTransaction *transaction))purchasingProcess
					  deferred:(void (^)(SKPaymentTransaction *transaction))deferredProcess
						failed:(void (^)(SKPaymentTransaction *transaction))failedProcess
					 purchased:(void (^)(CheckReceiptResult result,SKPaymentTransaction *transaction))purchasedProcess
					  restored:(void (^)(SKPaymentTransaction *transaction))restoredProcess;

- (void)buyProduct:(SKProduct *)product 
		 quantity:(NSInteger)quantity 
	  userAccount:(NSString *)userAccount
	 startProcess:(void (^)(void))startProcessBlock
		canNotPay:(void (^)(void))canNotPayBlock
 checkReceiptType:(CheckReceiptType)checkType;

- (BOOL)checkReceiptIsIncludeProduct:(SKProduct *)product;

///Download Host Content
- (void)setDownloadStateWaiting:(void (^)(SKDownload *download))downloadStateWaiting
						 active:(void (^)(SKDownload *download))downloadStateActive
						 paused:(void (^)(SKDownload *download))downloadStatePaused
					   finished:(void (^)(SKDownload *download))downloadStateFinished
						 failed:(void (^)(SKDownload *download))downloadStateFailed
					  cancelled:(void (^)(SKDownload *download))downloadStateCancelled;
- (void)startDownloads:(NSArray<SKDownload *> *)downloads NS_AVAILABLE_IOS(6_0);
- (void)pauseDownloads:(NSArray<SKDownload *> *)downloads NS_AVAILABLE_IOS(6_0);
- (void)resumeDownloads:(NSArray<SKDownload *> *)downloads NS_AVAILABLE_IOS(6_0);
- (void)cancelDownloads:(NSArray<SKDownload *> *)downloads NS_AVAILABLE_IOS(6_0);
- (NSMutableArray<NSString *> *)getDownloadFilePathArrayFromDownload:(SKDownload *)download;

///finish transaction
- (void)finishTransaction:(SKPaymentTransaction *)transaction;
@end
