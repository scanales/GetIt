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

#import "StackMob.h"
#import "StackMobConfiguration.h"
#import "StackMobPushRequest.h"
#import "StackMobRequest.h"
#import "StackMobAdditions.h"
#import "StackMobClientData.h"
#import "StackMobHerokuRequest.h"
#import "StackMobBulkRequest.h"
#import "StackMobAccessTokenRequest.h"

@interface StackMob()

@property (nonatomic, retain) StackMobRequest *currentRequest;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, retain) NSLock *queueLock;

- (void)queueRequest:(StackMobRequest *)request andCallback:(StackMobCallback)callback;
- (void)run;
- (void)next;
- (NSDictionary *)loadInfo;
- (StackMobRequest *)destroy:(NSString *)path withArguments:(NSDictionary *)arguments andHeaders:(NSDictionary *)headers andCallback:(StackMobCallback)callback;
- (NSString *) escapePath:(NSString *)path;
@end

#define ENVIRONMENTS [NSArray arrayWithObjects:@"production", @"development", nil]

@implementation StackMob

struct {
    unsigned int stackMobDidStartSession:1;
    unsigned int stackMobDidEndSession:1;
} delegateRespondsTo;

@synthesize requests = _requests;
@synthesize callbacks = _callbacks;
@synthesize session = _session;
@synthesize cookieStore = _cookieStore;

@synthesize currentRequest = _currentRequest;
@synthesize running = _running;
@synthesize queueLock = _queueLock;

@synthesize sessionDelegate = _sessionDelegate;

static StackMob *_sharedManager = nil;
static SMEnvironment environment;


+ (StackMob *)setApplication:(OAuthVersion)oauthVersion key:(NSString *)apiKey secret:(NSString *)apiSecret appName:(NSString *)appName subDomain:(NSString *)subDomain userObjectName:(NSString *)userObjectName apiVersionNumber:(NSNumber *)apiVersion
{
    if (_sharedManager == nil) {
        _sharedManager = [[super allocWithZone:NULL] init];
        environment = SMEnvironmentProduction;
        _sharedManager.session = [StackMobSession sessionForApplication:oauthVersion
                                                                    key:apiKey
                                                                 secret:apiSecret
                                                                appName:appName
                                                              subDomain:subDomain
                                                                 domain:SMDefaultDomain
                                                         userObjectName:userObjectName
                                                       apiVersionNumber:apiVersion];
        _sharedManager.requests = [NSMutableArray array];
        _sharedManager.callbacks = [NSMutableArray array];
        _sharedManager.queueLock = [[NSLock alloc] init];
        _sharedManager.cookieStore = [[[StackMobCookieStore alloc] initWithSession:_sharedManager.session] retain];
    }
    return _sharedManager;
}

+ (StackMob *)stackmob {
    if (_sharedManager == nil) {
        environment = SMEnvironmentProduction;
        
        _sharedManager = [[super allocWithZone:NULL] init];
        NSDictionary *appInfo = [_sharedManager loadInfo];
        if(appInfo){
            NSLog(@"Loading applicatino info from StackMob.plist is being deprecated for security purposes.");
            NSLog(@"Please define your application info in your app's prefix.pch");
            _sharedManager.session = [StackMobSession sessionForApplication:OAuth1
                                                                        key:[appInfo objectForKey:@"publicKey"]
                                                                     secret:[appInfo objectForKey:@"privateKey"]
                                                                    appName:[appInfo objectForKey:@"appName"]
                                                                  subDomain:[appInfo objectForKey:@"appSubdomain"]
                                                                     domain:[appInfo objectForKey:@"domain"]
                                                             userObjectName:[appInfo objectForKey:@"userObjectName"]
                                                           apiVersionNumber:[appInfo objectForKey:@"apiVersion"]];
            
        }
        else{
#ifdef STACKMOB_PUBLIC_KEY
            _sharedManager.session = [StackMobSession sessionForApplication:STACKMOB_OAUTH_VERSION
                                                                        key:STACKMOB_PUBLIC_KEY
                                                                     secret:STACKMOB_PRIVATE_KEY
                                                                    appName:STACKMOB_APP_NAME
#ifdef STACKMOB_APP_MOB
                                                                  subDomain:STACKMOB_APP_MOB
#else
                                                                  subDomain:SMSubdomainDefault
#endif
                                                                     domain:STACKMOB_APP_DOMAIN
                                                             userObjectName:STACKMOB_USER_OBJECT_NAME
                                                           apiVersionNumber:[NSNumber numberWithInt:STACKMOB_API_VERSION]];
#else
#warning "No configuration found"
#endif
            
        }
        _sharedManager.requests = [NSMutableArray array];
        _sharedManager.callbacks = [NSMutableArray array];
        _sharedManager.cookieStore = [[[StackMobCookieStore alloc] initWithSession:_sharedManager.session] retain];
    }

    return _sharedManager;
}

#pragma mark - Session Methods

- (StackMobRequest *)startSession{
    StackMobRequest *request = [StackMobRequest requestForMethod:@"startsession" withHttpVerb:POST];
    StackMob *this = self;
    [self queueRequest:request andCallback:^(BOOL success, id result) {
        if (delegateRespondsTo.stackMobDidStartSession) {
            [this.sessionDelegate stackMobDidStartSession];
        }  
    }];
    return request;
}

- (StackMobRequest *)endSession{
    StackMobRequest *request = [StackMobRequest requestForMethod:@"endsession" withHttpVerb:POST];
    StackMob *this = self;
    [self queueRequest:request andCallback:^(BOOL success, id result) {
        if (delegateRespondsTo.stackMobDidEndSession) {
            [this.sessionDelegate stackMobDidEndSession];
        }                
    }];    
    return request;
}

- (void)setSessionDelegate:(id)aSessionDelegate {
    if (self.sessionDelegate != aSessionDelegate) {
        [_sessionDelegate release];
        _sessionDelegate = aSessionDelegate;
        [_sessionDelegate retain];
        
        delegateRespondsTo.stackMobDidStartSession = [_sessionDelegate 
                                                      respondsToSelector:@selector(stackMobDidStartSession)];
        delegateRespondsTo.stackMobDidEndSession = [_sessionDelegate 
                                                    respondsToSelector:@selector(stackMobDidEndSession)];
        
        NSLog(@"delegate: %d %d", delegateRespondsTo.stackMobDidStartSession, delegateRespondsTo.stackMobDidEndSession);
    }
}

# pragma mark - User object Methods

- (StackMobRequest *)registerWithArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback
{
    StackMobRequest *request = [StackMobRequest requestForMethod:self.session.userObjectName
                                                   withArguments:arguments
                                                    withHttpVerb:POST]; 
    request.isSecure = YES;
    [self queueRequest:request andCallback:callback];
    
    return request;
}

- (StackMobRequest *)loginWithArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback
{
    StackMobRequest *request;
    
    if(self.session.oauthVersion == OAuth2)
    {
        request = [StackMobAccessTokenRequest requestForMethod:[NSString stringWithFormat:@"%@/accessToken", [self.session userObjectName]] withArguments:arguments];
    }
    else 
    {
       request = [StackMobRequest requestForMethod:[NSString stringWithFormat:@"%@/login", [self.session userObjectName]]
                              withArguments:arguments
                               withHttpVerb:GET];
       request.isSecure = YES;
    }

    
    _session.lastUserLoginName = [arguments valueForKey:@"username"];
    
    [self queueRequest:request andCallback:callback];
    
    return request;
}

- (StackMobRequest *)logoutWithCallback:(StackMobCallback)callback
{
    StackMobRequest *request = [StackMobRequest requestForMethod:[NSString stringWithFormat:@"%@/logout", self.session.userObjectName]
                                                   withArguments:[NSDictionary dictionary]
                                                    withHttpVerb:GET]; 
    
    if (self.session.oauthVersion == OAuth2) {
        [self queueRequest:request andCallback:^(BOOL success, id result) {
            self.session.oauth2TokenExpiration = [NSDate date];
            callback(success, result);
        }];

    }
    else {
        request.isSecure = YES;
        [self queueRequest:request andCallback:callback];
    }
    
        
    return request;
    
}

- (StackMobRequest *)getUserInfowithArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback
{
    return [self get:self.session.userObjectName withArguments:arguments andCallback:callback];
}

- (StackMobRequest *)getUserInfowithQuery:(StackMobQuery *)query andCallback:(StackMobCallback)callback {
    return [self get:self.session.userObjectName withQuery:query andCallback:callback];
}

# pragma mark - Facebook methods
- (StackMobRequest *)loginWithFacebookToken:(NSString *)facebookToken andCallback:(StackMobCallback)callback
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:facebookToken, @"fb_at", nil];
    StackMobRequest *request = [StackMobRequest userRequestForMethod:@"facebookLogin" withArguments:args withHttpVerb:GET];
    request.isSecure = YES;
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)registerWithFacebookToken:(NSString *)facebookToken username:(NSString *)username andCallback:(StackMobCallback)callback
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:facebookToken, @"fb_at", username, @"username", nil];
    StackMobRequest *request = [StackMobRequest userRequestForMethod:@"createUserWithFacebook" withArguments:args withHttpVerb:GET];
    request.isSecure = YES;
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)linkUserWithFacebookToken:(NSString *)facebookToken withCallback:(StackMobCallback)callback
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:facebookToken, @"fb_at", nil];
    StackMobRequest *request = [StackMobRequest userRequestForMethod:@"linkUserWithFacebook" withArguments:args withHttpVerb:GET];
    request.isSecure = YES;
    [self queueRequest:request andCallback:callback];
    return request;    
}

- (StackMobRequest *)postFacebookMessage:(NSString *)message withCallback:(StackMobCallback)callback
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", nil];
    StackMobRequest *request = [StackMobRequest userRequestForMethod:@"postFacebookMessage" withArguments:args withHttpVerb:GET];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)getFacebookUserInfoWithCallback:(StackMobCallback)callback
{
    StackMobRequest *request = [StackMobRequest userRequestForMethod:@"getFacebookUserInfo"withHttpVerb:GET];
    [self queueRequest:request andCallback:callback];
    return request;
}

# pragma mark - Twitter methods

- (StackMobRequest *)registerWithTwitterToken:(NSString *)token secret:(NSString *)secret username:(NSString *)username andCallback:(StackMobCallback)callback
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:token, @"tw_tk", secret, @"tw_ts", username, @"username", nil];
    StackMobRequest *request = [StackMobRequest userRequestForMethod:@"createUserWithTwitter" withArguments:args withHttpVerb:GET];
    request.isSecure = YES;
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)loginWithTwitterToken:(NSString *)token secret:(NSString *)secret andCallback:(StackMobCallback)callback
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:token, @"tw_tk", secret, @"tw_ts", nil];
    StackMobRequest *request = [StackMobRequest userRequestForMethod:@"twitterLogin" withArguments:args withHttpVerb:GET];
    request.isSecure = YES;
    [self queueRequest:request andCallback:callback];
    return request;    
}

- (StackMobRequest *)linkUserWithTwitterToken:(NSString *)token secret:(NSString *)secret andCallback:(StackMobCallback)callback
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:token, @"tw_tk", secret, @"tw_ts", nil];
    StackMobRequest *request = [StackMobRequest userRequestForMethod:@"linkUserWithTwitter" withArguments:args withHttpVerb:GET];
    request.isSecure = YES;
    [self queueRequest:request andCallback:callback];
    return request;    
}

- (StackMobRequest *)twitterStatusUpdate:(NSString *)message withCallback:(StackMobCallback)callback
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:message, @"tw_st", nil];
    StackMobRequest *request = [StackMobRequest userRequestForMethod:@"twitterStatusUpdate" withArguments:args withHttpVerb:GET];
    [self queueRequest:request andCallback:callback];
    return request;    
}

- (StackMobRequest *)getTwitterInfoWithCallback:(StackMobCallback)callback
{
    return [self get:@"getTwitterUserInfo" withCallback:callback];
}


# pragma mark - PUSH Notifications

- (StackMobRequest *)registerForPushWithUser:(NSString *)userId token:(NSString *)token andCallback:(StackMobCallback)callback
{
    return [self registerForPushWithUser:userId token:token overwrite:false andCallback:callback];
}

- (StackMobRequest *)registerForPushWithUser:(NSString *)userId token:(NSString *)token overwrite:(BOOL)overwrite andCallback:(StackMobCallback)callback
{
    NSDictionary *tokenDict = [NSDictionary dictionaryWithObjectsAndKeys:token, @"token",
                               @"ios", @"type",
                               nil];
    
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:userId, @"userId",
                          tokenDict, @"token",
                          overwrite, @"overwrite",
                          nil];
    
    StackMobPushRequest *pushRequest = [StackMobPushRequest requestForMethod:@"register_device_token_universal"];
    SMLog(@"args %@", body);
    [pushRequest setArguments:body];
    [self queueRequest:pushRequest andCallback:callback];
    return pushRequest;
}

- (StackMobRequest *)sendPushBroadcastWithArguments:(NSDictionary *)args andCallback:(StackMobCallback)callback {
    //{"kvPairs":{"key1":"val1",...}}
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:args, @"kvPairs", nil];
    StackMobPushRequest *request = [StackMobPushRequest requestForMethod:@"push_broadcast_universal" withArguments:body];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)sendPushToTokensWithArguments:(NSDictionary *)args withTokens:(NSArray *)tokens andCallback:(StackMobCallback)callback
{
    //{"payload":{"kvPairs":{"recipients":"asdf","alert":"asdfasdf"}},"tokens":[{"type":"iOS","token":"ASDF"}]}
    NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:args, @"kvPairs", nil];
    NSMutableArray * tokensArray = [NSMutableArray array];
    for(NSString * tkn in tokens) {
        NSDictionary * tknDict = [NSDictionary dictionaryWithObjectsAndKeys:tkn, @"token", @"ios", @"type", nil];
        [tokensArray addObject:tknDict];
    }
    
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:tokensArray, @"tokens", payload, @"payload", nil];
    StackMobPushRequest *request = [StackMobPushRequest requestForMethod:@"push_tokens_universal" withArguments:body];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)sendPushToUsersWithArguments:(NSDictionary *)args withUserIds:(NSArray *)userIds andCallback:(StackMobCallback)callback
{
    //{kvPairs: {"asdas":"asdasd"}, "userIds":["user1", "user2"]}
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:args, @"kvPairs", userIds, @"userIds", nil];
    StackMobPushRequest *request = [StackMobPushRequest requestForMethod:@"push_users_universal" withArguments:body];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)getPushTokensForUsers:(NSArray *)userIds andCallback:(StackMobCallback)callback
{
    //?userIds=user1,user2,user3
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:userIds, @"userIds", nil];
    StackMobPushRequest *request = [StackMobPushRequest requestForMethod:@"get_tokens_for_users_universal" withArguments:args];
    request.httpMethod = @"GET";
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)deletePushToken:(NSString *)token andCallback:(StackMobCallback)callback
{
    //{"token":"asdasdASASasd", "type":"android|ios"}
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:token, @"token", @"ios", @"type", nil];
    StackMobPushRequest *request = [StackMobPushRequest requestForMethod:@"remove_token_universal" withArguments:body];
    [self queueRequest:request andCallback:callback];
    return request;
}

# pragma mark - Heroku methods

- (StackMobRequest *)herokuGet:(NSString *)path withCallback:(StackMobCallback)callback
{
    StackMobHerokuRequest *request = [StackMobHerokuRequest requestForMethod:path
                                                               withArguments:NULL
                                                                withHttpVerb:GET];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)herokuGet:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback
{
    StackMobHerokuRequest *request = [StackMobHerokuRequest requestForMethod:path
                                                               withArguments:arguments
                                                                withHttpVerb:GET];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)herokuPost:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback
{
    StackMobHerokuRequest *request = [StackMobHerokuRequest requestForMethod:path
                                                               withArguments:arguments
                                                                withHttpVerb:POST];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)herokuPut:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback
{
    StackMobHerokuRequest *request = [StackMobHerokuRequest requestForMethod:path
                                                               withArguments:arguments
                                                                withHttpVerb:PUT];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)herokuDelete:(NSString *)path andCallback:(StackMobCallback)callback
{
    StackMobHerokuRequest *request = [StackMobHerokuRequest requestForMethod:path
                                                               withArguments:nil
                                                                withHttpVerb:DELETE];
    [self queueRequest:request andCallback:callback];
    return request;
}

# pragma mark - CRUD methods

- (NSString *) escapePath:(NSString *)path
{
    return [(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)path, NULL, CFSTR("?=&+;|"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) autorelease];   
}

- (StackMobRequest *)get:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback{
    StackMobRequest *request = [StackMobRequest requestForMethod:[self escapePath:path]
                                                   withArguments:arguments
                                                    withHttpVerb:GET]; 
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)get:(NSString *)path withQuery:(StackMobQuery *)query andCallback:(StackMobCallback)callback {
    StackMobRequest *request = [StackMobRequest requestForMethod:[self escapePath:path] withQuery:query withHttpVerb:GET];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)get:(NSString *)path withCallback:(StackMobCallback)callback
{
    StackMobRequest *request = [StackMobRequest requestForMethod:[self escapePath:path]
                                                   withArguments:NULL
                                                    withHttpVerb:GET];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)post:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback
{
    StackMobRequest *request = [StackMobRequest requestForMethod:[self escapePath:path]
                                                   withArguments:arguments
                                                    withHttpVerb:POST];
    
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)post:(NSString *)path forUser:(NSString *)user withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback
{
    NSDictionary *modifiedArguments = [NSMutableDictionary dictionaryWithDictionary:arguments];
    [modifiedArguments setValue:user forKey:self.session.userObjectName];
    StackMobRequest *request = [StackMobRequest requestForMethod:[NSString stringWithFormat:@"%@/%@", self.session.userObjectName, [self escapePath:path]]
                                                   withArguments:modifiedArguments
                                                    withHttpVerb:POST];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)post:(NSString *)path withBulkArguments:(NSArray *)arguments andCallback:(StackMobCallback)callback {
    StackMobBulkRequest *request = [StackMobBulkRequest requestForMethod:[self escapePath:path] withArguments:arguments];
    [self queueRequest:request andCallback:callback];
    
    return request;
}

- (StackMobRequest *)post:(NSString *)path withId:(NSString *)primaryId andField:(NSString *)relField andArguments:(NSDictionary *)args andCallback:(StackMobCallback)callback {
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@/%@", [self escapePath:path], primaryId, relField];
    return [self post:fullPath withArguments:args andCallback:callback];
}

- (StackMobRequest *)post:(NSString *)path withId:(NSString *)primaryId andField:(NSString *)relField andBulkArguments:(NSArray *)arguments andCallback:(StackMobCallback)callback {
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@/%@", [self escapePath:path], primaryId, relField];
    return [self post:fullPath withBulkArguments:arguments andCallback:callback];
}

- (StackMobRequest *)put:(NSString *)path withId:(NSString *)objectId andArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback {
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@", [self escapePath:path], objectId];
    
    StackMobRequest *request = [StackMobRequest requestForMethod:fullPath withArguments:arguments withHttpVerb:PUT];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)put:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback{
    StackMobRequest *request = [StackMobRequest requestForMethod:[self escapePath:path]
                                                   withArguments:arguments
                                                    withHttpVerb:PUT];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)put:(NSString *)path withId:(id)primaryId andField:(NSString *)relField andArguments:(NSArray *)args andCallback:(StackMobCallback)callback {
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@/%@", [self escapePath:path], primaryId, relField];
    StackMobBulkRequest *request = [StackMobBulkRequest requestForMethod:fullPath withArguments:args];
    request.httpMethod = [StackMobRequest stringFromHttpVerb:PUT];
    
    [self queueRequest:request andCallback:callback];
    
    return request;
}

- (StackMobRequest *)put:(NSString *)path withId:(NSString *)objectId updateCounterForField:(NSString *)field by:(int)value andCallback:(StackMobCallback)callback {
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@", [self escapePath:path], objectId];
    NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:value], [NSString stringWithFormat:@"%@[inc]", field], nil];
    StackMobRequest *request = [StackMobRequest requestForMethod:fullPath withArguments:arguments withHttpVerb:PUT];
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)destroy:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback{
    return [self destroy:[self escapePath:path] withArguments:arguments andHeaders:[NSDictionary dictionary] andCallback:callback];
}

- (StackMobRequest *)destroy:(NSString *)path withArguments:(NSDictionary *)arguments andHeaders:(NSDictionary *)headers andCallback:(StackMobCallback)callback {
    StackMobRequest *request = [StackMobRequest requestForMethod:[self escapePath:path]
                                                   withArguments:arguments
                                                    withHttpVerb:DELETE];
    [request setHeaders:headers];
    [self queueRequest:request andCallback:callback];
    return request;
    
}

- (StackMobRequest *)removeIds:(NSArray *)removeIds forSchema:(NSString *)schema andId:(NSString *)primaryId andField:(NSString *)relField withCallback:(StackMobCallback)callback {
    return [self removeIds:removeIds forSchema:schema andId:primaryId andField:relField shouldCascade:NO withCallback:callback];
}

- (StackMobRequest *)removeIds:(NSArray *)removeIds forSchema:(NSString *)schema andId:(NSString *)primaryId andField:(NSString *)relField shouldCascade:(BOOL)isCascade withCallback:(StackMobCallback)callback {
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@/%@/%@", schema, primaryId, relField, [self escapePath:[removeIds componentsJoinedByString:@","]]];
    NSDictionary *headers;
    if (isCascade == YES) {
        headers = [NSDictionary dictionaryWithObjectsAndKeys:@"true", @"X-StackMob-CascadeDelete", nil];
    } else {
        headers = [NSDictionary dictionary];
    }
    return [self destroy:fullPath 
           withArguments:[NSDictionary dictionary] 
              andHeaders:headers 
             andCallback:callback];
    
}


- (StackMobRequest *)removeId:(NSString *)removeId forSchema:(NSString *)schema andId:(NSString *)primaryId andField:(NSString *)relField withCallback:(StackMobCallback)callback {
    return [self removeId:removeId 
                forSchema:schema 
                    andId:primaryId 
                 andField:relField 
            shouldCascade:NO 
             withCallback:callback];
}

- (StackMobRequest *)removeId:(NSString *)removeId forSchema:(NSString *)schema andId:(NSString *)primaryId andField:(NSString *)relField shouldCascade:(BOOL)isCascade withCallback:(StackMobCallback)callback {
    return [self removeIds:[NSArray arrayWithObject:removeId] 
                 forSchema:schema 
                     andId:primaryId 
                  andField:relField 
             shouldCascade:isCascade 
              withCallback:callback];
    
}

- (StackMobRequest *)count:(NSString *)schema 
              withCallback:(StackMobCallback)callback
{
    return [self count:schema withQuery:[StackMobQuery query] andCallback:callback];
}

- (StackMobRequest *)count:(NSString *)schema
                 withQuery:(StackMobQuery *)query
              andCallback:(StackMobCallback)callback
{
    [query setRangeStart:0 andEnd:0];

    StackMobCallback userCallback = Block_copy(callback);
    __block StackMobRequest *request = [self get:schema withQuery:query andCallback:^(BOOL success, id result ) 
    {
        if(success)
        {
            int count = [request totalObjectCountFromPagination];
            if(count < 0)
            {
                // no header means we've got the results right here
                count = [((NSArray *) result) count];
            }
            userCallback(success, [NSNumber numberWithInt:count]);
        }
        else
        {
            userCallback(success, result);
        }
    }];
    
    return request;
}

# pragma mark - Forgot/Reset password

- (StackMobRequest *)forgotPasswordByUser:(NSString *)username andCallback:(StackMobCallback)callback
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username", nil];
    StackMobRequest *request = [StackMobRequest userRequestForMethod:@"forgotPassword" withArguments:args withHttpVerb:POST];
    request.isSecure = YES;
    [self queueRequest:request andCallback:callback];
    return request;
}

- (StackMobRequest *)resetPasswordWithOldPassword:(NSString*)oldPassword newPassword:(NSString*)newPassword andCallback:(StackMobCallback)callback
{
    NSDictionary *oldPWDict = [NSDictionary dictionaryWithObjectsAndKeys:oldPassword, @"password", nil];
    NSDictionary *newPWDict = [NSDictionary dictionaryWithObjectsAndKeys:newPassword, @"password", nil];
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:oldPWDict, @"old", newPWDict, @"new", nil];
    StackMobRequest *request = [StackMobRequest userRequestForMethod:@"resetPassword" withArguments:body withHttpVerb:POST];
    request.isSecure = YES;
    [self queueRequest:request andCallback:callback];
    return request;
}

# pragma mark - login checking

// Logged in user checking
- (NSString *) loggedInUser
{
    return [self isLoggedIn] ? _session.lastUserLoginName : nil;
}

- (BOOL) isLoggedIn
{
    if(self.session.oauthVersion == OAuth2) {
        return self.session.oauth2TokenValid;
    }
    else 
    {
        NSHTTPCookie *sessionCookie = [[_sharedManager cookieStore] sessionCookie];
        if(sessionCookie != nil) {
            BOOL cookieIsStillValid = [[[NSDate date] laterDate:[sessionCookie expiresDate]] isEqualToDate:[sessionCookie expiresDate]];
            return cookieIsStillValid && ![self isLoggedOut];
        }
    }

    return false;
}

- (BOOL) isUserLoggedIn:(NSString *)username
{
    return [username isEqualToString:[self loggedInUser]];
}

- (BOOL) isLoggedOut
{
    if(self.session.oauthVersion == OAuth2) {
        return self.session.oauth2TokenExpiration != nil && !self.session.oauth2TokenValid;
    }
    else 
    {
        NSHTTPCookie *sessionCookie = [_cookieStore sessionCookie];
        //The logged out cookie is a json string.
        return sessionCookie != nil && [[sessionCookie value] rangeOfString:@":"].location != NSNotFound;
    }
}



# pragma mark - Private methods
- (void)queueRequest:(StackMobRequest *)request andCallback:(StackMobCallback)callback
{
    request.delegate = self;
    
    [_queueLock lock];
    [self.requests addObject:request];
    if(callback)
        [self.callbacks addObject:Block_copy(callback)];
    else
        [self.callbacks addObject:[NSNull null]];
    [_queueLock unlock];
    
    [callback release];
    
    [self run];
}

- (void)run
{
    if(!self.running){
        if([self.requests isEmpty]) return;
        self.currentRequest = [self.requests objectAtIndex:0];
        [self.currentRequest sendRequest];
        self.running = YES;
    }
}

- (void)next
{
    self.running = NO;
    self.currentRequest = nil;
    [self run];
}

- (NSDictionary *)loadInfo
{
    NSString *filename = [[NSBundle mainBundle] pathForResource:@"StackMob" ofType:@"plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:filename];
    NSString *env = [ENVIRONMENTS objectAtIndex:(int)environment];
    
    NSMutableDictionary *appInfo = nil;
    if(info){
        appInfo = [NSMutableDictionary dictionaryWithDictionary:[info objectForKey:env]];
        if(![appInfo objectForKey:@"publicKey"] || [[appInfo objectForKey:@"publicKey"] length] < 1 || ![appInfo objectForKey:@"privateKey"] || [[appInfo objectForKey:@"privateKey"] length] < 1 ){
            [NSException raise:@"Initialization Error" format:@"Make sure you enter your publicKey and privateKey in StackMob.plist"];
        }
        else if(![appInfo objectForKey:@"appName"] || [[appInfo objectForKey:@"appName"] length] < 1 ){
            [NSException raise:@"Initialization Error" format:@"Make sure you enter your appName in StackMob.plist"];
        }
        else if(![appInfo objectForKey:@"appSubdomain"] || [[appInfo objectForKey:@"appSubdomain"] length] < 1 ){
            [NSException raise:@"Initialization Error" format:@"Make sure you enter your appSubdomain in StackMob.plist"];
        }
        else if(![appInfo objectForKey:@"domain"] || [[appInfo objectForKey:@"domain"] length] < 1 ){
            [NSException raise:@"Initialization Error" format:@"Make sure you enter your domain in StackMob.plist"];
        }
        else if(![appInfo objectForKey:@"apiVersion"]){
            [appInfo setValue:[NSNumber numberWithInt:1] forKey:@"apiVersion"];
        }
    }
    return appInfo;
}

#pragma mark - StackMobRequestDelegate

- (void)requestCompleted:(StackMobRequest*)request {
    if([self.requests containsObject:request]){
        NSInteger idx = [self.requests indexOfObject:request];
        id callback = [self.callbacks objectAtIndex:idx];
        SMLog(@"status %d", request.httpResponse.statusCode);
        if(callback != [NSNull null]){
            StackMobCallback mCallback = (StackMobCallback)callback;
            BOOL wasSuccessful = request.httpResponse.statusCode < 300 && request.httpResponse.statusCode > 199;
            [self.cookieStore addCookies:request];
            mCallback(wasSuccessful, [request result]);
            Block_release(mCallback);
        }else{
            SMLog(@"no callback found");
        }
        [self.callbacks removeObjectAtIndex:idx];
        [self.requests removeObject:request];
        [self next];
    }
}

# pragma mark - Singleton Conformity

static StackMob *sharedSession = nil;

+ (StackMob *)sharedManager
{
    if (sharedSession == nil) {
        sharedSession = [[super allocWithZone:NULL] init];
    }
    return sharedSession;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedManager] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (oneway void)release
{
    // do nothing
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (id)autorelease
{
    return self;
}
@end
