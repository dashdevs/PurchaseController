//
//  TransactionReceiptFetcher.m
//  Pods
//
//  Created by Igor Kulik on 6/17/19.
//

#import "TransactionReceiptFetcher.h"

@implementation TransactionReceiptFetcher

+ (NSData * _Nullable)directTransactionReceiptFor:(SKPaymentTransaction * _Nonnull)transaction {
    return [transaction transactionReceipt];
}

@end
