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

#import <Foundation/Foundation.h>
#import "StackMobConfiguration.h"
#import "StackMobVersion.h"

static NSString *const SMDefaultDomain = @"stackmob.com";
static NSString *const SMSubdomainDefault = @"mob1";

@interface StackMobSession : NSObject {
    NSString *url;
    NSString *pushURL;
    NSString *secureURL;
    NSString *regularURL;
    
	NSMutableArray* _delegates;
	NSString* _apiKey;
	NSString* _apiSecret;
	NSString* _appName;
    NSString* _subDomain;
	NSString* _domain;
    NSString* _userObjectName;
	NSString* _sessionKey;
	NSDate* _expirationDate;
	NSMutableArray* _requestQueue;
	NSDate* _lastRequestTime;
	int _requestBurstCount;
	NSTimer* _requestTimer;
    NSNumber* _apiVersionNumber;
    NSDate* _nextTimeCheck;
    NSTimeInterval _serverTimeDiff;
    NSString *_lastUserLoginName;
    int _oauthVersion;
    NSString *_oauth2Token;
    NSDate *_oauth2TokenExpiration;
    NSString *_oauth2Key;
}

/**
 * The URL used for API HTTP requests.
 */
@property(nonatomic,readonly) NSString* apiURL;

/**
 * The URL used for secure API HTTP requests.
 */
@property(nonatomic,readonly) NSString* apiSecureURL;

/**
 * The URL used for PUSH the notification API
 */
@property(nonatomic,readonly) NSString *pushURL;

/**
 * Your application's API key, as passed to the constructor.
 */
@property(nonatomic,readonly) NSString* apiKey;

/**
 * Your application's API secret, as passed to the constructor.
 */
@property(nonatomic,readonly) NSString* apiSecret;

/**
 * Your application's name, as passed to the constructor.
 */
@property(nonatomic,readonly) NSString* appName;

/**
 * Your application's domain name which defaults to stackmob.com or as passed to the constructor.
 */
@property(nonatomic,readonly) NSString* domain;

/**
 * Your application's subdomain, as passed to the constructor.
 */
@property(nonatomic,readonly) NSString* subDomain;

/**
 * Your application's user object name (ie - 'user' or 'account')
 */
@property(nonatomic,readonly) NSString* userObjectName;

/**
 * The API version number.
 */
@property(nonatomic,readonly) NSNumber* apiVersionNumber;

/**
 * The current user's session key.
 */
@property(nonatomic,readonly) NSString* sessionKey;

/**
 * The expiration date of the session key.
 */
@property(nonatomic,readonly) NSDate* expirationDate;

/**
 * The approximate time on the server
 */
@property(nonatomic,readonly, getter = getServerTime) NSDate* serverTime;

/**
 * The last username that logged in
 */
@property(nonatomic,retain) NSString* lastUserLoginName;

@property(readwrite) int oauthVersion;

@property(nonatomic,retain) NSString* oauth2Token;

@property(nonatomic,retain) NSDate* oauth2TokenExpiration;

@property(nonatomic,retain) NSString* oauth2Key;


/**
 * The globally shared session instance.
 */
+ (StackMobSession*)session;

/**
 * Constructs a session and stores it as the globally shared session instance.
 * Assumes using the default domain of stackmob.com
 *
 * @param key the application api key
 * @param secret the application secret api key
 * @param appName the application name
 * @param subDomain the application subDomain
 *
 */
+ (StackMobSession*)sessionForApplication:(int)oauthVersion key:(NSString*)key secret:(NSString*)secret
						   appName:(NSString*)appName subDomain:(NSString*)subDomain apiVersionNumber:(NSNumber*)apiVersionNumber;

/**
 * Constructs a session and stores it as the globally shared session instance.
 * Assumes using the default domain of stackmob.com
 *
 * @param key the application api key
 * @param secret the application secret api key
 * @param appName the application name
 * @param subDomain the application subDomain
 * @param domain overwrites the stackmob.com domain
 *
 */
+ (StackMobSession*)sessionForApplication:(int)oauthVersion key:(NSString*)key secret:(NSString*)secret
								  appName:(NSString*)appName 
								  subDomain:(NSString*)subDomain
					  			  domain:(NSString*)domain
          apiVersionNumber:(NSNumber*)apiVersionNumber;
/**
 * Constructs a session for an application.
 *
 * @param key the application api key
 * @param secret the application secret api key
 * @param appName the application name
 * @param subDomain the application subDomain
 * @param domain overwrites the stackmob.com domain
 */
- (StackMobSession*)initWithVersion:(int)oauthVersion key:(NSString*)key secret:(NSString*)secret appName:(NSString*)appName
					  subDomain:(NSString*)subDomain domain:(NSString*)domain apiVersionNumber:(NSNumber*)apiVersionNumber;

/**
 * Constructs a session for an application.
 *
 * @param key the application api key
 * @param secret the application secret api key
 * @param appName the application name
 * @param subDomain the application subDomain
 * @param domain overwrites the stackmob.com domain
 * @param userObjectName the name of the user object in your StackMob App
 */
+ (StackMobSession*)sessionForApplication:(int)oauthVersion 
                                      key:(NSString*)key 
                                   secret:(NSString*)secret 
                                  appName:(NSString*)appName
                                subDomain:(NSString*)subDomain 
                                   domain:(NSString*)domain 
                           userObjectName:(NSString*)userObjectName
                         apiVersionNumber:(NSNumber*)apiVersionNumber;

/**
 * Constructs a session for an application.
 *
 * @param key the application api key
 * @param secret the application secret api key
 * @param appName the application name
 * @param subDomain the application subDomain
 * @param domain overwrites the stackmob.com domain
 * @param userObjectName the name you gave to your user object on stackmob.com
 */
- (StackMobSession*)initWithVersion:(int)oauthVersion 
                                key:(NSString*)key 
                             secret:(NSString*)secret 
                            appName:(NSString*)appName
                          subDomain:(NSString*)subDomain 
                             domain:(NSString*)domain 
                     userObjectName:(NSString*)userObjectName
                   apiVersionNumber:(NSNumber*)apiVersionNumber;

/**
 * Returns the formatted url for the passedMethod.
 *
 * @param method name of the method to be called
 * @param userBasedRequest whether or not to prepend the user with the user
 * model name
 */
- (NSMutableString*)urlForMethod:(NSString*)method isUserBased:(BOOL)userBasedRequest;

/**
 * Returns the formatted SSL url for the passedMethod.
 *
 * @param name of the method to be called
 * @param userBasedRequest whether or not to prepend the user with the user
 * model name
 */
- (NSMutableString*)secureURLForMethod:(NSString*)method isUserBased:(BOOL)userBasedRequest;

/* 
 * Returns the User-Agent String
 */
- (NSString *)userAgentString;

- (BOOL) oauth2TokenValid;

/*
 * Update the server time diff
 */
-(void)recordServerTimeDiffFromHeader:(NSString*)header;

-(void)saveOAuth2AccessToken:(NSString *)token withExpiration:(NSDate *)date andKey:(NSString *)key;

-(BOOL)useOAuth2;

@end
