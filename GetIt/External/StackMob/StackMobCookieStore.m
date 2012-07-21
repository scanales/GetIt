// Copyright 2012 StackMob, Inc
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "StackMobCookieStore.h"

@interface StackMobCookieStore()
- (NSMutableDictionary *) initCookies;
@end

@implementation StackMobCookieStore

static NSString *cookieStoreKey;

- (StackMobCookieStore*)initWithSession:(StackMobSession *)session;
{
	if ((self = [super init])) {

        cookieStoreKey = [[@"stackmob." stringByAppendingString:[session apiKey]] retain];
	}
	return self;
}


- (void) addCookies:(StackMobRequest *)request
{
    NSHTTPURLResponse *response = request.httpResponse;
    NSMutableDictionary *cookies = [self initCookies];
    if([response allHeaderFields] != nil) {
        for(NSHTTPCookie *cookie in [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:[NSURL URLWithString:@""]]) {
            [cookies setObject:cookie forKey:[cookie name]];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:cookies] forKey:cookieStoreKey];
    [cookies release];
}

- (NSMutableDictionary *) initCookies
{
    NSData *storedCookes = [[NSUserDefaults standardUserDefaults] objectForKey:cookieStoreKey];
    if ([storedCookes length]) {
        return [[NSKeyedUnarchiver unarchiveObjectWithData:storedCookes] retain];
    } else {
        return [[NSMutableDictionary alloc] init];
    }
}

- (NSString *) cookieHeader
{
    NSMutableDictionary *cookies = [self initCookies];
    BOOL first = YES;
    NSString * cookieString = @"";
    for(NSHTTPCookie *cookie in [cookies allValues]) {
        if ([[cookie expiresDate] compare:[NSDate date]] != NSOrderedAscending)
        {
            cookieString = [cookieString stringByAppendingFormat:@"%@%@=%@", (first ? @"" : @";"), [cookie name], [cookie value]];
            first = NO;
        }
    }
    [cookies release];
    return cookieString;
}

- (NSHTTPCookie *) sessionCookie
{
    NSMutableDictionary *cookies = [self initCookies];
    for(NSHTTPCookie *cookie in [cookies allValues]) {
        if([[cookie name] rangeOfString:@"session_"].location == 0) return cookie;
    }
    return nil;
}
@end
