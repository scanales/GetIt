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
#import "StackMobSession.h"
#import "StackMobRequest.h"
#import "StackMobAccessTokenRequest.h"
#import "StackMobQuery.h"
#import "StackMobConfiguration.h"
#import "StackMobCookieStore.h"
#import "SMFile.h"
#import "StackMobAdditions.h"

typedef enum {
    SMEnvironmentProduction = 0,
    SMEnvironmentDevelopment = 1
} SMEnvironment;

typedef enum {
    OAuth1 = 1,
    OAuth2 = 2
} OAuthVersion;

typedef void (^StackMobCallback)(BOOL success, id result);

@protocol StackMobSessionDelegate <NSObject>

@optional
- (void)stackMobDidStartSession;
- (void)stackMobDidEndSession;

@end

@interface StackMob : NSObject <SMRequestDelegate>

@property (nonatomic, retain) StackMobSession *session;
@property (nonatomic, retain) NSMutableArray *callbacks;
@property (nonatomic, retain) NSMutableArray *requests;
@property (nonatomic, retain) StackMobCookieStore *cookieStore;

@property (nonatomic, retain) id<StackMobSessionDelegate> sessionDelegate;

/*
 * Manually configure your session.  Subsequent requests for the StackMob
 * singleton can use [StackMob stackmob]
 */
+ (StackMob *)setApplication:(OAuthVersion)oauthVersion key:(NSString *)apiKey secret:(NSString *)apiSecret appName:(NSString *)appName subDomain:(NSString *)subDomain userObjectName:(NSString *)userObjectName apiVersionNumber:(NSNumber *)apiVersion;

/*
 * Returns the pre-configured or auto-configured singleton
 * all instance methods are called on the singleton
 * If this method is called before setApplication:secret:appName:subDomain:userObjectName:apiVersonNumber
 * it will load the app config info from StackMob.plist in the main Bundle
 */
+ (StackMob *)stackmob;

/* 
 * Initializes a user session
 * Make sure to call this in appDidFinishLaunching
 */
- (StackMobRequest *)startSession;

/*
 * Ends a user session
 * Make sure to call this in applicationWillEnterBackground and applicationWillTerminate
 */
- (StackMobRequest *)endSession;

/********************* User based requests *************************/

/*
 * Registers a new userusing the user object name set when initializing StackMobSession
 * @param arguments A dictionary whose keys correspond to object field names on Stackmob Object Model
 */
- (StackMobRequest *)registerWithArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback;

/*
 * Logs a user in using the user object name set when initializing StackMobSession
 * @param arguments A dictionary whose keys correspond to object field names on Stackmob Object Model
 */
- (StackMobRequest *)loginWithArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback;

/*
 * Logs the current user out
 */
- (StackMobRequest *)logoutWithCallback:(StackMobCallback)callback;

/*
 * Gets a user object using the user object name set when initializing 
 * StackMobSession
 * @param arguments A dictionary whose keys correspond to object field names on Stackmob Object Model
 */
- (StackMobRequest *)getUserInfowithArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback;

/*
 * Gets user object data user the user object specified in configuration with a StackMobQuery
 * @param query StackMobQuery instance
 */
- (StackMobRequest *)getUserInfowithQuery:(StackMobQuery *)query andCallback:(StackMobCallback)callback;

/********************** Facebook Methods ******************/

/*
 * Authenticates a user in your StackMob app using their Facebook Token.  
 * Assumes the user is already registered
 * @param facebookToken the user's facebook access token
 */
- (StackMobRequest *)loginWithFacebookToken:(NSString *)facebookToken andCallback:(StackMobCallback)callback;

/* 
 * Registers a new user in your StackMob app using their facebook token
 * and a user selected username (you can default it to their Facebook username
 * assuming they have set one)
 * @param facebookToken the user's facebook access token
 */
- (StackMobRequest *)registerWithFacebookToken:(NSString *)facebookToken username:(NSString *)username andCallback:(StackMobCallback)callback;

/*
 * Links an existing user account to their facebook account.  Assumes the user
 * is currently logged in.
 * @param facebookToken the user's facebook token
 */
- (StackMobRequest *)linkUserWithFacebookToken:(NSString *)facebookToken withCallback:(StackMobCallback)callback;

/*
 * Post a message to facebook for the currently logged in user
 * assumes the user has connected to facebook
 * @param message the message to post
 */
- (StackMobRequest *)postFacebookMessage:(NSString *)message withCallback:(StackMobCallback)callback;

/*
 * Get the user info from facebook for the currently logged in user
 * assumes the user has connected to facebook
 */
- (StackMobRequest *)getFacebookUserInfoWithCallback:(StackMobCallback)callback;


/********************** Twitter methods ***********************/

/*
 * Registers a new user in your app using their twitter account
 * @param token the user's twitter token
 * @param secret the user's twitter secret
 */
- (StackMobRequest *)registerWithTwitterToken:(NSString *)token secret:(NSString *)secret username:(NSString *)username andCallback:(StackMobCallback)callback;

/* 
 * Login an existing user via Twitter
 * @param token the user's twitter token
 * @param secret the user's twitter secret
 */
- (StackMobRequest *)loginWithTwitterToken:(NSString *)token secret:(NSString *)secret andCallback:(StackMobCallback)callback;

/*
 * Link an existing user to their twitter account
 * @param token the user's token
 * @param secret the user's secret
 */
- (StackMobRequest *)linkUserWithTwitterToken:(NSString *)token secret:(NSString *)secret andCallback:(StackMobCallback)callback;

/*
 * Send a status update to twitter
 * @param message the status update to send
 */
- (StackMobRequest *)twitterStatusUpdate:(NSString *)message withCallback:(StackMobCallback)callback;

/*
 * Get the user info from twitter for the currently logged in user
 */
- (StackMobRequest *)getTwitterInfoWithCallback:(StackMobCallback)callback;

/********************** PUSH Notifications ********************/

/* 
 * Register a User for PUSH notifications
 * @param userId the user's user Id or username
 * @param token the device's PUSH notification token
 * @param arguments a Dictionary 
 */
- (StackMobRequest *)registerForPushWithUser:(NSString *)userId token:(NSString *)token andCallback:(StackMobCallback)callback;

/* 
 * Register a User for PUSH notifications
 * @param userId the user's user Id or username
 * @param token the device's PUSH notification token
 * @param overwrite whether to overwrite existing entries
 * @param arguments a Dictionary 
 */
- (StackMobRequest *)registerForPushWithUser:(NSString *)userId token:(NSString *)token overwrite:(BOOL)overwrite andCallback:(StackMobCallback)callback;

/*
 * Send a push notification broadcast
 * @param args push request arguments, the dictionary should contain the message, badge and alert (badge and alert optional)
 */
- (StackMobRequest *)sendPushBroadcastWithArguments:(NSDictionary *)args andCallback:(StackMobCallback)callback;

/*
 * Send a push notification to specific tokens
 * @param args push request arguments, the dictionary should contain the message, badge and alert (badge and alert optional)
 * @param tokens a list of tokens to which to send args
 */
- (StackMobRequest *)sendPushToTokensWithArguments:(NSDictionary *)args withTokens:(NSArray *)tokens andCallback:(StackMobCallback)callback;

/*
 * Send a push notification to a set of users
 * @param args push request arguments, the dictionary should contain the message, badge and alert (badge and alert optional)
 * @param userIds  
 */
- (StackMobRequest *)sendPushToUsersWithArguments:(NSDictionary *)args withUserIds:(NSArray *)userIds andCallback:(StackMobCallback)callback;

/*
 * Get all tokens for each of the given user IDs
 * @param userIds the users whose tokens to get
 */
- (StackMobRequest *)getPushTokensForUsers:(NSArray *)userIds andCallback:(StackMobCallback)callback;

/*
 * Delete a push token
 * @param token the token to delete
 */
- (StackMobRequest *)deletePushToken:(NSString *)token andCallback:(StackMobCallback)callback;

/********************** CRUD Methods **********************/
/* 
 * Get the object with name "path" and arguments dictionary
 * @param arguments a dictionary whose keys correspond to object field names on Stackmob Object Model
 */
- (StackMobRequest *)get:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback;

/* 
 * Get the object with name "path" with no arguments.  This will return all items of object type
 * @param path the name of the object to get in your stackmob app
 */
- (StackMobRequest *)get:(NSString *)path withCallback:(StackMobCallback)callback;

/*
 * Get data for object with StackMobQuery
 * @param query StackMobQuery instance
 */
- (StackMobRequest *)get:(NSString *)path withQuery:(StackMobQuery *)query andCallback:(StackMobCallback)callback;

/* 
 * POST the arguments to the given object model with name of "path"
 * @param path the name of the object in your stackmob app to be created
 * @param arguments a dictionary whose keys correspond to field names of the object in your Stackmob app
 */
- (StackMobRequest *)post:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback;

/*
 * POST the arguments for a user
 * @param path the name of the object in your stackmob app to be created
 * @param arguments a dictionary whose keys correspond to field names of the object in your Stackmob app
 */
- (StackMobRequest *)post:(NSString *)path forUser:(NSString *)user withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback;

/*
 * Bulk Insertion
 * @param bulkArguments - an array of NSDictionary instances to insert
 */
- (StackMobRequest *)post:(NSString *)path
        withBulkArguments:(NSArray *)arguments
              andCallback:(StackMobCallback)callback;

/*
 * POST one related object with Relations API Extensions 
 */
- (StackMobRequest *)post:(NSString *)path 
                   withId:(NSString *)primaryId 
                 andField:(NSString *)relField 
             andArguments:(NSDictionary *)args
              andCallback:(StackMobCallback)callback;

/*
 * POST many related objects with Relations API Extensions
 */
- (StackMobRequest *)post:(NSString *)path
                   withId:(NSString *)primaryId
                 andField:(NSString *)relField
         andBulkArguments:(NSArray *)arguments
              andCallback:(StackMobCallback)callback;


/*
 * PUT the arguments to the given object path
 * @param path the name of the object in your Stackmob app
 * @param objId the id of the object to update
 * @param arguments a Dictionary of attributes whose  keys correspond to field names of the object in your Stackmob app
 */
- (StackMobRequest *)put:(NSString *)path withId:(NSString *)objectId andArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback;


/*
 * PUT the arguments to the given object path
 * @path the name of the object in your Stackmob app
 * @param arguments a Dictionary of attributes whose  keys correspond to field names of the object in your Stackmob app
 */
- (StackMobRequest *)put:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback __attribute__((deprecated));

/*
 * Atomically update an array or has many relationship
 * with relations API extensions
 */
- (StackMobRequest *)put:(NSString *)path 
                  withId:(NSString *)primaryId 
                andField:(NSString *)relField 
            andArguments:(NSArray *)args 
             andCallback:(StackMobCallback)callback;

/*
 * Uses the PUT operation to update the atomic counter of the supplied field name
 * @param path the name of the object in your Stackmob app
 * @param objId the id of the object to update
 * @param field the name of the field whose counter will be updated
 * @param value the value the the field's counter will be inc/dec by
 */
- (StackMobRequest *)put:(NSString *)path withId:(NSString *)objectId updateCounterForField:(NSString *)field by:(int)value andCallback:(StackMobCallback)callback;

/* 
 * DELETE the object at the given path
 * @path the name of the object in your stackmob app
 * @param arguments a Dictonary with one key that corresponds to your object's primary key
 *   the value of which is the item to delete
 */
- (StackMobRequest *)destroy:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback;

/*
 * automically remove elements from an array or has many relationship
 */
- (StackMobRequest *)removeIds:(NSArray *)removeIds 
                     forSchema:(NSString *)schema 
                         andId:(NSString *)primaryId 
                      andField:(NSString *)relField 
                  withCallback:(StackMobCallback)callback;

/*
 * automically remove elements from an array or has many relationship
 * @param shouldCascade if YES the X-StackMob-CascadeDelete header will be set
 */
- (StackMobRequest *)removeIds:(NSArray *)removeIds 
                     forSchema:(NSString *)schema 
                         andId:(NSString *)primaryId 
                      andField:(NSString *)relField 
                 shouldCascade:(BOOL)isCascade
                  withCallback:(StackMobCallback)callback;
/*
 * automically remove an element from an array or has many relationship or unset the value of a has one relationship
 */
- (StackMobRequest *)removeId:(NSString *)removeId 
                    forSchema:(NSString *)schema 
                        andId:(NSString *)primaryId 
                     andField:(NSString *)relField 
                 withCallback:(StackMobCallback)callback;

/*
 * automically remove an element from an array or has many relationship or unset the value of a has one relationship
 * @param shouldCascade if YES the X-StackMob-CascadeDelete header will be set
 */
- (StackMobRequest *)removeId:(NSString *)removeId 
                    forSchema:(NSString *)schema 
                        andId:(NSString *)primaryId 
                     andField:(NSString *)relField 
                shouldCascade:(BOOL)isCascade
                 withCallback:(StackMobCallback)callback;

- (StackMobRequest *)count:(NSString *)schema 
              withCallback:(StackMobCallback)callback;

- (StackMobRequest *)count:(NSString *)schema
                 withQuery:(StackMobQuery *)query
              andCallback:(StackMobCallback)callback;



/**************** Heroku Methods *****************/

/*
 * Perform a GET request on a custom heroku action.
 * @param path should be the full path without the leading / to your action
 */
- (StackMobRequest *)herokuGet:(NSString *)path withCallback:(StackMobCallback)callback;

/*
 * Perform a GET request on a custom heroku action.
 * @param path should be the full path without the leading / to your action
 * @param arguments a dictionary to be converted to query params
 */
- (StackMobRequest *)herokuGet:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback;

/*
 * POST the arguments for a heroku action on heroku
 * @param path the name of the object in your stackmob app to be created (without 'heroku/proxy')
 * @param arguments a dictionary whose keys correspond to field names of the object in your Stackmob app
 */
- (StackMobRequest *)herokuPost:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback;

/*
 * PUT the arguments for a heroku action on heroku
 * @param path the name of the object in your stackmob app to be created (without 'heroku/proxy')
 * @param arguments a dictionary whose keys correspond to field names of the object in your Stackmob app
 */
- (StackMobRequest *)herokuPut:(NSString *)path withArguments:(NSDictionary *)arguments andCallback:(StackMobCallback)callback;

/*
 * DELETE the object at specified path
 * @param path should be the full path without the leading / to your action
 */
- (StackMobRequest *)herokuDelete:(NSString *)path andCallback:(StackMobCallback)callback;

/**************** Forgot/Reset Methods *****************/

/*
 * Sends off an email with a temporary password for a user.
 */
- (StackMobRequest *)forgotPasswordByUser:(NSString *)username andCallback:(StackMobCallback)callback;

/*
 * Resets the password of a logged in user
 */
- (StackMobRequest *)resetPasswordWithOldPassword:(NSString*)oldPassword newPassword:(NSString*)newPassword andCallback:(StackMobCallback)callback;

// Logged in user checking
- (NSString *) loggedInUser;

- (BOOL) isLoggedIn;

- (BOOL) isUserLoggedIn:(NSString *)username;

- (BOOL) isLoggedOut;


@end

