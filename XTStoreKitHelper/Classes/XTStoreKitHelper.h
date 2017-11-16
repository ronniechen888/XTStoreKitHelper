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

- (void)saveReceiptToCloudOrUserDefault;

- (BOOL)checkReceiptIsIncludeProduct:(SKProduct *)product;

///Download Host Content
- (void)setDownloadStateWaiting:(void (^)(SKDownload *download))downloadStateWaiting
						 active:(void (^)(SKDownload *download))downloadStateActive
						 paused:(void (^)(SKDownload *download))downloadStatePaused
					   finished:(void (^)(SKDownload *download))downloadStateFinished
						 failed:(void (^)(SKDownload *download))downloadStateFailed
					  cancelled:(void (^)(SKDownload *download))downloadStateCancelled;
- (void)startDownloads:(NSArray<SKDownload *> *)downloads;
- (void)pauseDownloads:(NSArray<SKDownload *> *)downloads;
- (void)resumeDownloads:(NSArray<SKDownload *> *)downloads;
- (void)cancelDownloads:(NSArray<SKDownload *> *)downloads;
- (NSMutableArray<NSString *> *)getDownloadFilePathArrayFromDownload:(SKDownload *)download;

///Restore transaction
- (void)restoreCompletedTransactionsWithApplicationUsername:(NSString *)username success:(void (^)(void))successHandle failed:(void (^)(NSError *error))failedHandle;

///Finish transaction
- (void)finishTransaction:(SKPaymentTransaction *)transaction finishedHandle:(void (^)(SKPaymentTransaction *transaction))finishedHandle;
@end
