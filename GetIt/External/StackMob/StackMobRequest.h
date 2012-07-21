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
#import "StackMobConfiguration.h"
#import "StackMobQuery.h"
#import "JSONKit.h"

@class StackMob;

typedef enum {
	GET,
	POST,
	PUT,
	DELETE
} SMHttpVerb;

@protocol SMRequestDelegate;

@interface StackMobRequest : NSObject
{
    NSURLConnection*        mConnection;
    id<SMRequestDelegate>   mDelegate;
    SEL                     mSelector;
    BOOL                    mIsSecure;
    NSString*               mMethod;
    NSMutableDictionary*    mArguments;
    NSMutableDictionary*    mHeaders;
    NSData*                 mBody;
    NSMutableData*          mConnectionData;
    NSDictionary*           mResult;
    NSError*                mConnectionError;
    BOOL                    _requestFinished;
    NSString*               mHttpMethod;
    NSHTTPURLResponse*      mHttpResponse;
	
	@protected
    BOOL userBased;
	StackMobSession *session;
}

@property(readwrite, retain) id<SMRequestDelegate> delegate;
@property(readwrite, copy) NSString* method;
@property(readwrite, copy) NSString* httpMethod;
@property(readwrite) BOOL isSecure;
@property(readwrite, retain) NSURLConnection* connection;
@property(readwrite, retain) NSDictionary* result;
@property(readwrite, retain) NSError* connectionError;
@property(readwrite, retain) NSData *body;
@property(readonly) BOOL finished;
@property(readonly) NSHTTPURLResponse* httpResponse;
@property(readonly, getter=getStatusCode) NSInteger statusCode;
@property(readonly, getter=getBaseURL) NSString* baseURL;
@property(readonly, getter=getURL) NSURL* url;
@property(nonatomic) BOOL userBased;

+ (NSString*)stringFromHttpVerb:(SMHttpVerb)httpVerb;

/* 
 * Standard CRUD requests
 */
+ (id)request;
+ (id)requestForMethod:(NSString*)method;
+ (id)requestForMethod:(NSString*)method withHttpVerb:(SMHttpVerb) httpVerb;
+ (id)requestForMethod:(NSString*)method withArguments:(NSDictionary*)arguments withHttpVerb:(SMHttpVerb) httpVerb;
+ (id)requestForMethod:(NSString*)method withQuery:(StackMobQuery *)query withHttpVerb:(SMHttpVerb) httpVerb;
+ (id)requestForMethod:(NSString *)method withData:(NSData *)data;

/* 
 * User based requests 
 * Use these to execute a method on a user object
 */
+ (id)userRequest;
+ (id)userRequestForMethod:(NSString *)method withHttpVerb:(SMHttpVerb)httpVerb;
+ (id)userRequestForMethod:(NSString*)method withArguments:(NSDictionary*)arguments withHttpVerb:(SMHttpVerb)httpVerb;
+ (id)userRequestForMethod:(NSString *)method withQuery:(StackMobQuery *)query withHttpVerb:(SMHttpVerb)httpVerb;

/*
 * Create a request for an iOS PUSH notification
 * @param arguments a dictionary of arguments including :alert, :badge and :sound
 */
+ (id)pushRequestWithArguments:(NSDictionary*)arguments withHttpVerb:(SMHttpVerb) httpVerb;

/**
 * Convert a NSDictionary to JSON
 * @param dict the dictionary to convert to JSON
 */
+ (NSData *)JsonifyNSDictionary:(NSMutableDictionary *)dict withErrorOutput:(NSError **)error;

/*
 * Set parameters for requests
 */
- (void)setArguments:(NSDictionary*)arguments;
- (void)setValue:(NSString*)value forArgument:(NSString*)argument;
- (void)setInteger:(NSUInteger)value forArgument:(NSString*)argument;
- (void)setBool:(BOOL)value forArgument:(NSString*)argument;

/*
 * Set headers for requests, overwrites all headers set for the request
 * @param headers, the headers to set
 */
- (void)setHeaders:(NSDictionary *)headers;

/*
 * Send a configured request and wait for callback
 */
- (void)sendRequest;

/*
 * Cancel and ignore a request in progress
 */
- (void)cancel;

/* Send a synchronous request
 * This is useful if you are creating requests in a separate thread already
 * @param address of NSError
 */
- (id)sendSynchronousRequestProvidingError:(NSError**)error __attribute__((deprecated));
- (id)sendSynchronousRequest;

- (NSString *)contentType;

// return the post body as NSData
- (NSData *)postBody;

- (int)totalObjectCountFromPagination;

/* translate enum to string */
+ (NSString*)stringFromHttpVerb:(SMHttpVerb)httpVerb;

- (id) resultFromSuccessString:(NSString *)textResult;

- (BOOL)useOAuth2;

- (NSString *)createMACHeaderForOAuth2;

@end

@protocol SMRequestDelegate <NSObject>

@optional
- (void)requestCompleted:(StackMobRequest *)request;

@end


