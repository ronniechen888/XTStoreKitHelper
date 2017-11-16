# XTStoreKitHelper

[![CI Status](http://img.shields.io/travis/ronniechen888/XTStoreKitHelper.svg?style=flat)](https://travis-ci.org/ronniechen888/XTStoreKitHelper)
[![Version](https://img.shields.io/cocoapods/v/XTStoreKitHelper.svg?style=flat)](http://cocoapods.org/pods/XTStoreKitHelper)
[![License](https://img.shields.io/cocoapods/l/XTStoreKitHelper.svg?style=flat)](http://cocoapods.org/pods/XTStoreKitHelper)
[![Platform](https://img.shields.io/cocoapods/p/XTStoreKitHelper.svg?style=flat)](http://cocoapods.org/pods/XTStoreKitHelper)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

XTStoreKitHelper is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'XTStoreKitHelper'
```

## Usage

```objective-c
/// Get XTStoreKitHelper's singleton object,you can use this class in your appplication anywhere.
/// 获取这个类的单例模式，你可以方便的在你程序的任何一个角落使用这个类。
+ (instancetype)sharedStoreHelper;

/// Use this method,your application can judge your user's payment ability.
/// 通过这个方法，你的应用程序可以判断你的用户是否具有支付能力。
+ (BOOL)canMakePayment;

/// Use this method,you can get the locallize string for the price of target product.
/// 通过这个方法，你能获取到这个项目的本地化价格字符串。
+ (NSString *)currencyPriceWithProduct:(SKProduct *)product;

/// Maybe you need to add this method in your application's application:didFinishLaunchingWithOptions: to add transaction observer.This is aim for some transactions not finished when your application is over,it will help you conitnue these transactions.
/// 有可能你需要将这个方法添加到你程序里的application:didFinishLaunchingWithOptions:启动方法里。因为你的应用程序有可能结束时购买交易还没结束，添加了这个方法后在这种情况下下次启动程序会有助于继续走上次交易的流程。
- (void)addTransactionObserver;

/// Remove the transaction observer.
- (void)removeTransactionObserver;

/// Set an array for your selling products's identifiers.
/// 将你需要售卖的内购项目标示添加到数组里进行设置。
- (void)setProductIdentifiers:(NSArray *)productIdentifiers;

/// Validate your products' identifiers are correct by remote appstore server?
/// 通过这个方法去远程校验这些产品的标识符是否正确。
- (void)validateProductsReceiveResponse:(void (^)(NSArray<SKProduct *> *products,NSArray<NSString *> *invalidProductIdentifiers))validateResponse
receiveFinish:(void (^)(void))validatDidFinish
receiveFail:(void (^)(NSError *))validateDidFail;

/// Stop the validate process.
- (void)stopValidateProcess;

/// Set pay process's handler.It usually be calling before buy method.It aims to custom your UI dispaly.
/// 设置支付流程的回调函数。它通常在buy方法前面去调用，目的是为了定制你购买时想用的UI显示效果。
- (void)setPayProcessPurchasing:(void (^)(SKPaymentTransaction *transaction))purchasingProcess
deferred:(void (^)(SKPaymentTransaction *transaction))deferredProcess
failed:(void (^)(SKPaymentTransaction *transaction))failedProcess
purchased:(void (^)(CheckReceiptResult result,SKPaymentTransaction *transaction))purchasedProcess
restored:(void (^)(SKPaymentTransaction *transaction))restoredProcess;

/// After your application called this method,it would begin to excute buying product process.
/// 在你调用这个方法后，程序开始进入购买流程。
- (void)buyProduct:(SKProduct *)product 
quantity:(NSInteger)quantity 
userAccount:(NSString *)userAccount
startProcess:(void (^)(void))startProcessBlock
canNotPay:(void (^)(void))canNotPayBlock
checkReceiptType:(CheckReceiptType)checkType;

/// Save receipt to user defaults or iCloud when you want.You should know the consuming product's record will may be clean after the receipt refresh in next time.
/// 将你想要的收据保存到本地user default里或者icloud 云端。你需要知道消耗型产品有可能在下次收据刷新时被清除。
- (void)saveReceiptToCloudOrUserDefault;

/// Check the local receipt is include the target product?
/// 校验本地收据是否包含目标项目。
- (BOOL)checkReceiptIsIncludeProduct:(SKProduct *)product;

/// Refresh the receipt by remote server manually.
/// 手动的去远程服务器刷新当前的收据。
- (void)refreshReceiptOnSuccess:(void (^)(void))successHandle failed:(void (^)(void))failedHandle;

/// These methods aim for download host content when you set your non-consuming product's content.
/// 这一系列方法是为了去下载你非消耗型项目里设置的资源文件。
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

/// Use this method, you can get the array of your resources' full path.
/// 使用这个方法，你能获取到一个包含你资源文件全路径的数组。
- (NSMutableArray<NSString *> *)getDownloadFilePathArrayFromDownload:(SKDownload *)download;

/// Maybe you need to restore your tansactions manuall.It usually be setting for a new device when someone has bought your product.
/// 有可能你需要这个手动恢复的功能，因为有的人有可能已经购买过你的项目，但是他现在是用的一台新设备。
- (void)restoreCompletedTransactionsWithApplicationUsername:(NSString *)username success:(void (^)(void))successHandle failed:(void (^)(NSError *error))failedHandle;

/// You need to finish transaction manually when your product has been SKPaymentTransactionStatePurchased state.
/// 当你的产品购买成功时，你需要手动的去结束这个交易。
- (void)finishTransaction:(SKPaymentTransaction *)transaction finishedHandle:(void (^)(SKPaymentTransaction *transaction))finishedHandle;
```
## Demo Code
### To test the demo,you need to use the demo account: ronniechen123@123.com and password: Github123 .
```objective-c
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
[[XTStoreKitHelper sharedStoreHelper] finishTransaction:transaction finishedHandle:^(SKPaymentTransaction *transaction) {
NSLog(@"Finish transaction");
}];
}
}else if(result == CheckReceiptResultNo){

UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"警告" message:@"凭据有异常！" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
[alertView show];

[[XTStoreKitHelper sharedStoreHelper] finishTransaction:transaction finishedHandle:^(SKPaymentTransaction *transaction) {
NSLog(@"Finish transaction");
}];
}else{

[[XTStoreKitHelper sharedStoreHelper] finishTransaction:transaction finishedHandle:^(SKPaymentTransaction *transaction) {
NSLog(@"Finish transaction");
}];
}
} restored:^(SKPaymentTransaction *transaction) {

}];
[[XTStoreKitHelper sharedStoreHelper] buyProduct:product quantity:1 userAccount:nil startProcess:nil canNotPay:nil checkReceiptType:CheckReceiptTypeAppStore];
```
## Author

ronniechen888, 576892817@qq.com

## License

XTStoreKitHelper is available under the MIT license. See the LICENSE file for more info.
