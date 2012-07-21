//
//  StackMobAccessTokenRequest.m
//  StackMobiOS
//
//  Created by Douglas Rapp on 7/2/12.
//  Copyright (c) 2012 StackMob, Inc. All rights reserved.
//

#import "StackMobAccessTokenRequest.h"
#import "StackMobAdditions.h"

@implementation StackMobAccessTokenRequest

+ (id)requestForMethod:(NSString *)method withArguments:(NSDictionary *)arguments {
    StackMobAccessTokenRequest *request = [[[StackMobAccessTokenRequest alloc] init] autorelease];
    request.method = method;
    request.isSecure = YES;
    NSMutableDictionary *dict = [arguments mutableCopy];
    [dict setObject:@"mac" forKey:@"token_type"];
    [request setArguments: dict];
    [dict release];
    request.httpMethod = [StackMobRequest stringFromHttpVerb:POST];
    
    return request;
}

- (id) resultFromSuccessString:(NSString *)textResult
{
    NSDictionary * result = [textResult objectFromJSONString];
    NSString *accessToken = [result valueForKey:@"access_token"];
    NSNumber *expiration = [result valueForKey:@"expires_in"];
    NSString *key = [result valueForKey:@"mac_key"];
    [session saveOAuth2AccessToken:accessToken withExpiration:[NSDate dateWithTimeIntervalSinceNow:expiration.intValue] andKey:key];
    return [[result valueForKey:@"stackmob"] valueForKey:@"user"];
    
}

- (NSString *)contentType {
    return @"application/x-www-form-urlencoded";
}

- (NSData *)postBody {
    return [[mArguments queryString] dataUsingEncoding:NSUTF8StringEncoding]; 
}

@end
