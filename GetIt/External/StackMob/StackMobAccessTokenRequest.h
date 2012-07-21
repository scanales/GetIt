//
//  StackMobAccessTokenRequest.h
//  StackMobiOS
//
//  Created by Douglas Rapp on 7/2/12.
//  Copyright (c) 2012 StackMob, Inc. All rights reserved.
//

#import "StackMobRequest.h"
//#import "StackMob.h"

@interface StackMobAccessTokenRequest : StackMobRequest

+ (id)requestForMethod:(NSString *)method withArguments:(NSDictionary *)arguments;

@end
