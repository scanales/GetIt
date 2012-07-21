// Copyright 2011 StackMob, Inc
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

#import "StackMobSession.h"

@interface StackMobSession(Private)
- (void)setup;

- (NSString *)oauth2TokenKey;
- (NSString *)oauth2TokenExpirationKey;
- (NSString *)oauth2Key;

@end

@interface StackMobSession()
@property(nonatomic,readonly) NSDate* nextTimeCheck;
@property(nonatomic,assign) NSTimeInterval serverTimeDiff;
@end

@implementation StackMobSession

static const int kMaxBurstRequests = 3;
static const NSTimeInterval kBurstDuration = 2;

static StackMobSession* sharedSession = nil;
static NSString *const serverTimeDiffKey = @"stackmob.servertimediff";

@synthesize apiKey = _apiKey;
@synthesize apiSecret = _apiSecret;
@synthesize appName = _appName;
@synthesize domain = _domain;
@synthesize subDomain = _subDomain;
@synthesize userObjectName = _userObjectName;
@synthesize apiVersionNumber = _apiVersionNumber;
@synthesize sessionKey = _sessionKey;
@synthesize expirationDate = _expirationDate;
@synthesize nextTimeCheck = _nextTimeCheck;
@synthesize serverTimeDiff = _serverTimeDiff;
@synthesize lastUserLoginName = _lastUserLoginName;
@synthesize oauthVersion = _oauthVersion;
@synthesize oauth2Token = _oauth2Token;
@synthesize oauth2TokenExpiration = _oauth2TokenExpiration;
@synthesize oauth2Key = _oauth2Key;
@synthesize pushURL;

+ (StackMobSession*)session {
	return sharedSession;
}

+ (StackMobSession*)sessionForApplication:(int)oauthVersion 
                                      key:(NSString*)key 
                                   secret:(NSString*)secret
                                  appName:(NSString*)appName
                                subDomain:(NSString*)subDomain
                         apiVersionNumber:(NSNumber*)apiVersionNumber 
{
	return [self sessionForApplication:oauthVersion key:key secret:secret appName:appName 
							 subDomain:subDomain domain:SMDefaultDomain apiVersionNumber:apiVersionNumber];
}

+ (StackMobSession*)sessionForApplication:(int)oauthVersion 
                                      key:(NSString*)key 
                                   secret:(NSString*)secret 
                                  appName:(NSString*)appName
                                subDomain:(NSString*)subDomain 
                                   domain:(NSString*)domain 
                         apiVersionNumber:(NSNumber*)apiVersionNumber
{
	StackMobSession* session = [[[StackMobSession alloc] initWithVersion:oauthVersion
                                                                    key:key 
                                                                  secret:secret 
                                                                 appName:appName
                                                               subDomain:subDomain 
                                                                  domain:domain
                                                        apiVersionNumber:apiVersionNumber] autorelease];
	return session;
}

+ (StackMobSession*)sessionForApplication:(int)oauthVersion 
                                      key:(NSString*)key 
                                   secret:(NSString*)secret 
                                  appName:(NSString*)appName
                                subDomain:(NSString*)subDomain 
                                   domain:(NSString*)domain 
                           userObjectName:(NSString*)userObjectName
                         apiVersionNumber:(NSNumber*)apiVersionNumber
{
	StackMobSession* session = [[[StackMobSession alloc] initWithVersion:oauthVersion
                                                                     key:key 
                                                                  secret:secret 
                                                                 appName:appName
                                                               subDomain:subDomain 
                                                                  domain:domain
                                                          userObjectName:userObjectName
                                                        apiVersionNumber:apiVersionNumber] autorelease];
    SMLog(@"apiVersionNumber %@", apiVersionNumber);
    
	return session;
}

- (NSMutableString*)urlForMethod:(NSString*)method isUserBased:(BOOL)userBasedRequest isSecure:(BOOL)isSecure
{
  NSMutableArray *parts = [NSMutableArray array];
  [parts addObject:(isSecure ? secureURL : regularURL)];
  
  if(userBasedRequest) [parts addObject:self.userObjectName];
  [parts addObject:method];
  
  NSMutableString *urlString = [NSMutableString stringWithString:[parts componentsJoinedByString:@"/"]];
  return urlString;
}

- (NSMutableString*)secureURLForMethod:(NSString*)method isUserBased:(BOOL)userBasedRequest {
  return  [self urlForMethod:method isUserBased:userBasedRequest isSecure:YES];
}

- (NSMutableString*)urlForMethod:(NSString*)method isUserBased:(BOOL)userBasedRequest {
  return  [self urlForMethod:method isUserBased:userBasedRequest isSecure:NO];
}

- (StackMobSession*)initWithVersion:(int)oauthVersion 
                                key:(NSString*)key 
                             secret:(NSString*)secret 
                            appName:(NSString*)appName
                          subDomain:(NSString*)subDomain 
                             domain:(NSString*)domain 
                   apiVersionNumber:(NSNumber*)apiVersionNumber
{
	if ((self = [super init])) {
		if (!sharedSession) {
			sharedSession = self;
		}
        _oauthVersion = oauthVersion;
		_apiKey = [key copy];
		_apiSecret = [secret copy];
		_appName = [appName copy];
        _subDomain = [subDomain copy];
		_domain = [domain copy];
        _apiVersionNumber = [apiVersionNumber copy];
        [self setup];
	}
	return self;
}

- (StackMobSession*)initWithVersion:(int)oauthVersion 
                                key:(NSString*)key 
                             secret:(NSString*)secret 
                            appName:(NSString*)appName
                          subDomain:(NSString*)subDomain 
                             domain:(NSString*)domain 
                     userObjectName:(NSString *)userObjectName
                   apiVersionNumber:(NSNumber*)apiVersionNumber
{
	if ((self = [super init])) {
		if (!sharedSession) {
			sharedSession = self;
		}
        _oauthVersion = oauthVersion;
        _apiKey = [key copy];
        _apiSecret = [secret copy];
        _appName = [appName copy];
        _subDomain = [subDomain copy];
        _domain = [domain copy];
        _userObjectName = [userObjectName copy];
        _apiVersionNumber = [apiVersionNumber copy];
        [self setup];
	}
	return self;
}

- (void)setup{
    _sessionKey = nil;
    _expirationDate = nil;
    _requestQueue = [[NSMutableArray alloc] init];
    _lastRequestTime = nil;
    _requestBurstCount = 0;
    _requestTimer = nil; 
    url = [[NSString stringWithFormat:@"api.%@.%@", _subDomain, _domain] retain];
    pushURL = [[NSString stringWithFormat:@"http://push.%@.%@", _subDomain, _domain] retain];
    secureURL = [[NSString stringWithFormat:@"https://%@", url] retain];
    regularURL = [[NSString stringWithFormat:@"http://%@", url] retain];
    _serverTimeDiff = [[NSUserDefaults standardUserDefaults] doubleForKey:serverTimeDiffKey];
    _nextTimeCheck = [[NSDate date] retain];
    _oauth2Token = [[NSUserDefaults standardUserDefaults] objectForKey:[self oauth2TokenKey]];
    _oauth2TokenExpiration = [[NSUserDefaults standardUserDefaults] objectForKey:[self oauth2TokenExpirationKey]];
}

- (void)dealloc {
    SMLog(@"StackMobSession: dealloc");
	if (sharedSession == self) {
		sharedSession = nil;
	}
	
	[_apiKey release];
	[_apiSecret release];
	[_appName release];
    [_subDomain release];
	[_domain release];
    [_userObjectName release];
    [_apiVersionNumber release];
	[_sessionKey release];
	[_expirationDate release];
	[_lastRequestTime release];
	[_requestQueue release];
	[_requestTimer release];
    [_lastUserLoginName release];
	[url release];
	[secureURL release];
	[regularURL release];
	[super dealloc];
    SMLog(@"StackMobSession: dealloc finished");
}

- (NSString*)apiURL {
	return regularURL;
}

- (NSString*)apiSecureURL {
	return secureURL;
}

- (BOOL) oauth2TokenValid
{
    return self.oauth2TokenExpiration != nil && [[self.oauth2TokenExpiration laterDate:[NSDate date]] isEqualToDate:self.oauth2TokenExpiration];
}


- (NSString *)userAgentString {
    return [NSString stringWithFormat:@"StackMob (iOS; %@)/%@", STACKMOB_SDK_VERSION, _appName];
}

- (NSDate *)getServerTime {
    SMLog(@"Applying a time difference of %f", _serverTimeDiff);
    return [NSDate dateWithTimeIntervalSinceNow:_serverTimeDiff];
}

-(void)recordServerTimeDiffFromHeader:(NSString*)header {
    if (header != nil) {
        
        NSDateFormatter *rfcFormatter = [[NSDateFormatter alloc] init];
        [rfcFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
        NSDate *serverTime = [rfcFormatter dateFromString:header];
        [rfcFormatter release];
        _serverTimeDiff = [serverTime timeIntervalSinceDate:[NSDate date]];
        SMLog(@"Server time is %@ and diff is %f", serverTime, _serverTimeDiff);
        if([[NSDate date] earlierDate:_nextTimeCheck] == _nextTimeCheck) {
            // Save the date to persistent storage every ten minutes
            [[NSUserDefaults standardUserDefaults] setDouble:_serverTimeDiff forKey:serverTimeDiffKey];
            SMLog(@"Server time diff after saving to NSUSerDefaults is %f", [[NSUserDefaults standardUserDefaults] doubleForKey:serverTimeDiffKey]);
            NSDate *newDate = [[NSDate dateWithTimeIntervalSinceNow:10 * 60] retain];
            [_nextTimeCheck release];
            _nextTimeCheck = newDate;
        }
    }
}

- (NSString *)oauth2TokenKey
{
    return [NSString stringWithFormat:@"%@.token", _apiKey];
}
- (NSString *)oauth2TokenExpirationKey
{
    return [NSString stringWithFormat:@"%@.token.expiration", _apiKey];
}

-(void)saveOAuth2AccessToken:(NSString *)token withExpiration:(NSDate *)date andKey:(NSString *)key
{
    self.oauth2Key = key;
    self.oauth2Token = token;
    self.oauth2TokenExpiration = date;
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:[self oauth2TokenKey]];
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:[self oauth2TokenExpirationKey]];
    
}

-(BOOL)useOAuth2
{
    return [self oauthVersion] == 2;
}

@end
