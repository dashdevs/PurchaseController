//
//  ReceiptFetcher.h
//  PurchaseController
//
//  Created on 7/30/19.
//

#import <Foundation/Foundation.h>
@import StoreKit;

NS_ASSUME_NONNULL_BEGIN

@interface DirectReceiptFetcher: NSObject

+ (NSData *) directReceiptOfTransaction: (SKPaymentTransaction *) transaction;

@end


NS_ASSUME_NONNULL_END
