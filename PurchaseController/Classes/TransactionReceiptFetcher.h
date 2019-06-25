//
//  TransactionReceiptFetcher.h
//  Pods
//
//  Created by Igor Kulik on 6/17/19.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface TransactionReceiptFetcher: NSObject

+ (NSData * _Nullable)directTransactionReceiptFor:(SKPaymentTransaction * _Nonnull)transaction;

@end
