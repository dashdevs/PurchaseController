//
//  ReceiptFetcher.m
//  PurchaseController
//
//  Created by Valeriy Efimov on 7/30/19.
//

#import "DirectReceiptFetcher.h"

@implementation DirectReceiptFetcher

+ (NSData *)directReceiptOfTransaction:(SKPaymentTransaction *)transaction {
    return [transaction transactionReceipt];
}

@end
