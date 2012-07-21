//
//  StackMobBulkRequest.h
//  StackMobiOS
//
//  Created by Jordan West on 12/1/11.
//  Copyright (c) 2011 StackMob, Inc. All rights reserved.
//

#import "StackMobRequest.h"

@interface StackMobBulkRequest : StackMobRequest

@property (nonatomic, copy) NSArray *bulkArguments;

+ (id)requestForMethod:(NSString *)method withArguments:(NSArray *)arguments;
+ (NSData *)JsonifyNSArray:(NSArray *)dict withErrorOutput:(NSError **)error;

@end
