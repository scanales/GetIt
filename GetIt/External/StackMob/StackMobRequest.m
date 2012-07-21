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

#import "StackMobRequest.h"
#import "StackMob.h"
#import "Reachability.h"
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "StackMobAdditions.h"
#import "StackMobClientData.h"
#import "StackMobSession.h"
#import "StackMobPushRequest.h"
#import "NSData+JSON.h"
#import "SMFile.h"

@interface StackMobRequest (Private)
+ (NSString*)stringFromHttpVerb:(SMHttpVerb)httpVerb;
- (void)setBodyForRequest:(OAMutableURLRequest *)request;
- (NSString*)getAcceptHeaderForVersion:(NSNumber *)version;
@end

@implementation StackMobRequest;

@synthesize connection = mConnection;
@synthesize delegate = mDelegate;
@synthesize method = mMethod;
@synthesize isSecure = mIsSecure;
@synthesize result = mResult;
@synthesize connectionError = _connectionError;
@synthesize body;
@synthesize httpMethod = mHttpMethod;
@synthesize httpResponse = mHttpResponse;
@synthesize finished = _requestFinished;
@synthesize userBased;

# pragma mark - Memory Management
- (void)dealloc
{
	[self cancel];
	[mConnectionData release];
	[mConnection release];
	[mDelegate release];
	[mMethod release];
	[mResult release];
	[mHttpMethod release];
	[mHttpResponse release];
    [mHeaders release];    
    [mArguments release];
	[super dealloc];
}

# pragma mark - Initialization

+ (id)request	
{
	return [[[StackMobRequest alloc] init] autorelease];
}

+ (id)userRequest
{
    StackMobRequest *request = [StackMobRequest request];
    request.userBased = YES;
    return request;
}

+ (id)requestForMethod:(NSString*)method
{
	return [StackMobRequest requestForMethod:method withHttpVerb:GET];
}	

+ (id)requestForMethod:(NSString*)method withHttpVerb:(SMHttpVerb)httpVerb
{
	return [StackMobRequest requestForMethod:method withArguments:nil withHttpVerb:httpVerb];
}

+ (id)userRequestForMethod:(NSString *)method withHttpVerb:(SMHttpVerb)httpVerb
{
	return [StackMobRequest userRequestForMethod:method withArguments:nil withHttpVerb:httpVerb];    
}

+ (id)requestForMethod:(NSString*)method withArguments:(NSDictionary*)arguments withHttpVerb:(SMHttpVerb)httpVerb
{
	StackMobRequest* request = [StackMobRequest request];
	request.method = method;
	request.httpMethod = [self stringFromHttpVerb:httpVerb];
	if (arguments != nil) {
		[request setArguments:arguments];
	}
	return request;
}

+ (id)userRequestForMethod:(NSString*)method withArguments:(NSDictionary*)arguments withHttpVerb:(SMHttpVerb)httpVerb
{
	StackMobRequest* request = [StackMobRequest userRequest];
	request.method = method;
	request.httpMethod = [self stringFromHttpVerb:httpVerb];
	if (arguments != nil) {
		[request setArguments:arguments];
	}
	return request;
}

+ (id)userRequestForMethod:(NSString *)method withQuery:(StackMobQuery *)query withHttpVerb:(SMHttpVerb)httpVerb {
    StackMobRequest *request = [StackMobRequest userRequestForMethod:method withArguments:query.params withHttpVerb:httpVerb];
    [request setHeaders:query.headers];
    return request;
}

+ (id)requestForMethod:(NSString*)method withQuery:(StackMobQuery *)query withHttpVerb:(SMHttpVerb) httpVerb {
    StackMobRequest *request = [StackMobRequest requestForMethod:method withArguments:[query params] withHttpVerb:httpVerb];
    [request setHeaders:query.headers];
    return request;
}


+ (id)requestForMethod:(NSString *)method withData:(NSData *)data{
    StackMobRequest *request = [StackMobRequest request];
    request.method = method;
    request.httpMethod = [self stringFromHttpVerb:POST];
    request.body = data;
    return request;
}

+ (id)pushRequestWithArguments:(NSDictionary*)arguments withHttpVerb:(SMHttpVerb) httpVerb {
	StackMobRequest* request = [StackMobPushRequest request];
	request.httpMethod = [self stringFromHttpVerb:httpVerb];
	if (arguments != nil) {
		[request setArguments:arguments];
	}
	return request;
}

+ (NSString*)stringFromHttpVerb:(SMHttpVerb)httpVerb
{
	switch (httpVerb) {
		case POST:
			return @"POST";	
		case PUT:
			return @"PUT";
		case DELETE:
			return @"DELETE";	
		default:
			return @"GET";
	}
}

- (NSString *)getBaseURL {
    if(mIsSecure) {
        return [session secureURLForMethod:self.method isUserBased:userBased];
    }
    return [session urlForMethod:self.method isUserBased:userBased];
}

- (NSURL*)getURL
{
    // nil method is an invalid request
	if(!self.method) return nil;
    
    // build URL and add query string if necessary
    NSMutableArray *urlComponents = [NSMutableArray arrayWithCapacity:2];
    [urlComponents addObject:self.baseURL]; 
    
    if (([[self httpMethod] isEqualToString:@"GET"] || [[self httpMethod] isEqualToString:@"DELETE"]) &&    
		[mArguments count] > 0) {
		[urlComponents addObject:[mArguments queryString]];
	}
    
    NSString *urlString = [urlComponents componentsJoinedByString:@"?"];
    SMLog(@"%@", urlString);
    
	return [NSURL URLWithString:urlString];
}

- (NSInteger)getStatusCode
{
	return [mHttpResponse statusCode];
}


- (id)init
{
	self = [super init];
    if(self){
        self.delegate = nil;
        self.method = nil;
        self.result = nil;
        mArguments = [[NSMutableDictionary alloc] init];
        mHeaders = [[NSMutableDictionary alloc] init];
        mConnectionData = [[NSMutableData alloc] init];
        mResult = nil;
        session = [StackMobSession session];
    }
	return self;
}

#pragma mark -

- (void)setArguments:(NSDictionary*)arguments
{
	[mArguments setDictionary:arguments];
}

- (void)setValue:(NSString*)value forArgument:(NSString*)argument
{
	[mArguments setValue:value forKey:argument];
}

- (void)setInteger:(NSUInteger)value forArgument:(NSString*)argument
{
	[mArguments setValue:[NSString stringWithFormat:@"%u", value] forKey:argument];
}

- (void)setBool:(BOOL)value forArgument:(NSString*)argument
{
	[mArguments setValue:(value ? @"true" : @"false") forKey:argument];
}

- (void)setHeaders:(NSDictionary *)headers {
    [mHeaders setDictionary:headers];
}

+ (NSData *)JsonifyNSDictionary:(NSMutableDictionary *)dict withErrorOutput:(NSError **)error {
    
    static id(^unsupportedClassSerializerBlock)(id) = ^id(id object) {
        if ( [object isKindOfClass:[NSData class]] ) {
            NSString* base64String = [(NSData*)object JSON];
            
            return base64String;
        }
        else if([object isKindOfClass:[SMFile class]]) {
            return [(SMFile *)object JSON];
        }
        else {
            return nil;
        }
    };
    
    NSData * json = [dict JSONDataWithOptions:JKSerializeOptionNone
        serializeUnsupportedClassesUsingBlock:unsupportedClassSerializerBlock
                                        error:error];
    return json;
}

- (NSString*)getAcceptHeaderForVersion:(NSNumber *)version
{
    return [NSString stringWithFormat:@"application/vnd.stackmob+json; version=%d",[version intValue]];
}

- (BOOL)useOAuth2
{
    return session.useOAuth2;
}

- (void)sendRequest
{
	_requestFinished = NO;
    
    SMLog(@"StackMob method: %@", self.method);
    SMLog(@"Request with url: %@", self.url);
    SMLog(@"Request with HTTP Method: %@", self.httpMethod);
    
	OAConsumer *consumer = [[[OAConsumer alloc] initWithKey:session.apiKey
                                                    secret:session.apiSecret] autorelease];
    
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:self.url
																   consumer:consumer
																	  token:nil
																	  realm:nil
														  signatureProvider:nil // use the default method, HMAC-SHA1
                                                                      nonce:nil
                                                                  timestamp:[NSString stringWithFormat:@"%d", (long) [session.serverTime timeIntervalSince1970]]];
    SMLog(@"httpMethod %@", [self httpMethod]);
    if([self.method isEqualToString:@"startsession"]){
        [mArguments setValue:[StackMobClientData sharedClientData].clientDataString forKey:@"cd"];
    }
	[request setHTTPMethod:[self httpMethod]];
    
	[request addValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[request addValue:@"deflate" forHTTPHeaderField:@"Accept-Encoding"];
    [request addValue:[session userAgentString] forHTTPHeaderField:@"User-Agent"];
    [request addValue:[self getAcceptHeaderForVersion:[session apiVersionNumber]] forHTTPHeaderField:@"Accept"];
    for(NSString *header in mHeaders) {
        if (!([header isEqualToString:@"Accept-Encoding"] || [header isEqualToString:@"User-Agent"] || [header isEqualToString:@"Content-Type"])) {
            [request addValue:(NSString *)[mHeaders objectForKey:header] forHTTPHeaderField:header];
        }
    }
    
    [request addValue:[[[StackMob stackmob] cookieStore] cookieHeader] forHTTPHeaderField:@"Cookie"];
    
    if(session.oauthVersion == OAuth2)
    {
        [request addValue:session.apiKey forHTTPHeaderField:@"X-StackMob-API-Key"];
        if(session.oauth2TokenValid)
        {
            NSString *oauth2MAC = [self createMACHeaderForOAuth2];
            [request addValue:oauth2MAC forHTTPHeaderField:@"Authorization"];
            SMLog(@"request headers are: %@", [request allHTTPHeaderFields]);
        }
    }
    else
    {
        [request prepare];
    }

    [self setBodyForRequest:request];
    
    
    SMLog(@"StackMobRequest: sending asynchronous oauth request: %@", request);
    
	[mConnectionData setLength:0];
	self.result = nil;
    self.connectionError = nil;
	self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease]; // Why retaining this when already retained by synthesized method?
    [request release];
}

- (void)setBodyForRequest:(OAMutableURLRequest *)request {
    if (!([[self httpMethod] isEqualToString: @"GET"] || [[self httpMethod] isEqualToString:@"DELETE"])) {    
        NSData * postData = [self postBody];
#if DEBUG
        NSString * postDataString = [[[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding] autorelease];
        //Chop out big binary blobs that would make the logs unreadable
        NSString *binaryMatcher = @"(Content-Transfer-Encoding: base64)([^\"]{10})([^\"]*)(\")";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:binaryMatcher options:0 error:NULL];
        postDataString = [regex stringByReplacingMatchesInString:postDataString
                                                         options:0
                                                           range:NSMakeRange(0, [postDataString length])
                                                    withTemplate:@"$1$2(truncated)$4"];
        SMLog(@"POST Data: %@", postDataString);
#endif
        [request setHTTPBody:postData];
        [request addValue:[self contentType] forHTTPHeaderField: @"Content-Type"]; 
	}
}

- (NSString *)contentType {
    return @"application/json";
}

- (NSData *)postBody {
    NSError* error = nil;
    return [StackMobRequest JsonifyNSDictionary:mArguments withErrorOutput:&error];
}

- (int)totalObjectCountFromPagination 
{
    if(mHttpResponse != nil) 
    {
        NSString *contentRange = [[mHttpResponse allHeaderFields] valueForKey:@"Content-Range"];
        if(contentRange != nil) {
            NSArray* parts = [contentRange componentsSeparatedByString: @"/"];
            if([parts count] != 2) return -1;
            NSString *lastPart = [parts objectAtIndex: 1];
            if([lastPart isEqualToString:@"*"]) return -2;
            if([lastPart isEqualToString:@"0"]) return 0;
            int count = [lastPart intValue];
            if(count == 0) return -1; //real zero was filtered out above
            return count;
        }
    }
    return -1;
}

- (void)cancel
{
	[self.connection cancel];
	self.connection = nil;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
	mHttpResponse = [(NSHTTPURLResponse*)response copy];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
	if (!data) {
		SMLog(@"StackMobRequest: Received data but it was nil");
		return;
	}
    
	[mConnectionData appendData:data];
	
    SMLog(@"StackMobRequest: Got data of length %u", [mConnectionData length]);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	_requestFinished = YES;
    
	SMLog(@"StackMobRequest %p: Connection failed! Error - %@ %@",
          self,
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
	// inform the user
	self.result = [NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], @"statusDetails", nil];  
	if (self.delegate && [self.delegate respondsToSelector:@selector(requestCompleted:)])
        [[self delegate] requestCompleted:self];
}

- (id) resultFromSuccessString:(NSString *)textResult
{
    return [textResult objectFromJSONString];
}


- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
	_requestFinished = YES;
    
    SMLog(@"StackMobRequest %p: Received Request: %@", self, self.method);
    
	NSString *textResult = nil;
	NSDictionary *result = nil;
    NSInteger statusCode = [self getStatusCode];
    
    SMLog(@"RESPONSE CODE %d", statusCode);
    if ([mConnectionData length] > 0) {
        textResult = [[[NSString alloc] initWithData:mConnectionData encoding:NSUTF8StringEncoding] autorelease];

        
#if DEBUG
        
        if ([textResult length] > 2000)
        {
            SMLog(@"textResult was greater than 2000, truncating for logging purposes");
            SMLog(@"RESPONSE BODY %@", [textResult substringToIndex:2000]);
        }
        else {
            SMLog(@"RESPONSE BODY %@", textResult);
        }
        
#endif
         
    }
    
    [session recordServerTimeDiffFromHeader:[[mHttpResponse allHeaderFields] valueForKey:@"Date"]];
    
    
    if (textResult == nil) {
        result = [NSDictionary dictionary];
    }   
    else {
        @try{
            [mConnectionData setLength:0];
            if (statusCode < 400) {
                result = [self resultFromSuccessString:textResult];
            } else {
                NSDictionary *errResult = (NSDictionary *)[textResult objectFromJSONString]; 
                NSString *failMsg;
                if ([errResult objectForKey:@"error"] == nil) {
                    failMsg = [NSString stringWithFormat:@"Response failed with code: %d", statusCode];
                    
                } else {
                    failMsg = [errResult objectForKey:@"error"];
                }
                result = [NSError errorWithDomain:@"StackMob"         
                                             code:1 
                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:failMsg, NSLocalizedDescriptionKey, nil]];   
            }
        }
        @catch (NSException *e) { // catch parsing errors
            NSString *failMsg = [NSString stringWithFormat:@"Response failed with code: %d", statusCode];
            result = [NSError errorWithDomain:@"StackMob"         
                                         code:1 
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:failMsg, NSLocalizedDescriptionKey, nil]];
            SMLog(@"Unable to parse json '%@'", textResult);
        }
    }
    
    SMLog(@"Request Processed: %@", self.method);
    
    self.result = result;
	
    if (!self.delegate) SMLog(@"No delegate");
    
	if (self.delegate && [self.delegate respondsToSelector:@selector(requestCompleted:)]){
        SMLog(@"Calling delegate %d, self %d", [mDelegate retainCount], [self retainCount]);
        [self.delegate requestCompleted:self];
    } else {
        SMLog(@"Delegate does not respond to selector\ndelegate: %@", mDelegate);
    }
}

- (id) sendSynchronousRequestProvidingError:(NSError**)error {
    SMLog(@"Sending Request: %@", self.method);
    SMLog(@"Request URL: %@", self.url);
    SMLog(@"Request HTTP Method: %@", self.httpMethod);
    id result = [self sendSynchronousRequest];
    if(error)
        *error = self.connectionError;
    return result;
}

- (id) sendSynchronousRequest {
    SMLog(@"StackMobRequest %p: Sending Synch Request httpMethod=%@ method=%@ url=%@", self, self.httpMethod, self.method, self.url);
	
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:session.apiKey
													secret:session.apiSecret];
	
	OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:self.url
																   consumer:consumer
																	  token:nil   // we don't need a token
																	  realm:nil   // should we set a realm?
														  signatureProvider:nil
                                                                      nonce:nil
                                                                  timestamp:[NSString stringWithFormat:@"%d", (long) [session.serverTime timeIntervalSince1970]]] autorelease]; // use the default method, HMAC-SHA1
	[consumer release];
	[request setHTTPMethod:[self httpMethod]];
	
	[request addValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[request addValue:@"deflate" forHTTPHeaderField:@"Accept-Encoding"];
	if(session.oauthVersion == OAuth2)
    {
        [request addValue:session.apiKey forHTTPHeaderField:@"X-StackMob-API-Key"];
        if(session.oauth2TokenValid)
        {
            NSString *oauth2MAC = [self createMACHeaderForOAuth2];
            [request addValue:oauth2MAC forHTTPHeaderField:@"Authorization"];
            SMLog(@"request headers are: %@", [request allHTTPHeaderFields]);
        }
    }
    else
    {
        [request prepare];
    }
	if (![[self httpMethod] isEqualToString: @"GET"]) {
		[request setHTTPBody:[[mArguments JSONString] dataUsingEncoding:NSUTF8StringEncoding]];	
		NSString *contentType = [NSString stringWithFormat:@"application/json"];
		[request addValue:contentType forHTTPHeaderField: @"Content-Type"];
	}
    [request addValue:[self getAcceptHeaderForVersion:[session apiVersionNumber]] forHTTPHeaderField:@"Accept"];
	
	[mConnectionData setLength:0];
    
    SMLog(@"StackMobRequest %p: sending synchronous oauth request: %@ with headers %@", self, request, [request allHTTPHeaderFields]);
    
    _requestFinished = NO;
    self.connectionError = nil;
    self.delegate = nil;
    self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while (!_requestFinished && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil]) {
        loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
    }
    
    return self.result;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"%@: %@", [super description], self.url];
}

- (NSString *)createMACHeaderForOAuth2
{
    // get the id
    NSString *access_token = [session oauth2Token];
    double timestamp = [[NSDate date] timeIntervalSince1970];
    // create the nonce
    NSString *nonce = [NSString stringWithFormat:@"n%d", arc4random() % 10000];    
    // create the mac
    NSString *key = [session oauth2Key];
    NSArray *hostAndPort = [[NSString stringWithFormat:@"api.%@.%@", [[[StackMob stackmob] session] subDomain], [[[StackMob stackmob] session] domain]] componentsSeparatedByString:@":"];
    NSString *host = [hostAndPort objectAtIndex:0];
    NSString *port = [hostAndPort count] > 1 ? [hostAndPort objectAtIndex:1] : @"80";
    NSString *httpVerb = self.httpMethod;
    NSString *uri = [NSString stringWithFormat:@"/%@", self.method];
    
    if (([[self httpMethod] isEqualToString:@"GET"] || [[self httpMethod] isEqualToString:@"DELETE"]) &&    
		[mArguments count] > 0) {
		uri = [uri stringByAppendingFormat:@"?%@", [mArguments queryString]];
	}

    // create base
    NSArray *baseArray = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%.f", timestamp], nonce, httpVerb, uri, host, port, nil];
    unichar newline = 0x0A;
    NSString *baseString = [baseArray componentsJoinedByString:[NSString stringWithFormat:@"%C", newline]];
    baseString = [baseString stringByAppendingString:[NSString stringWithFormat:@"%C", newline]];
    baseString = [baseString stringByAppendingString:[NSString stringWithFormat:@"%C", newline]];
    
    //bstring through bin to string using crypto
    OAHMAC_SHA1SignatureProvider *provider = [[OAHMAC_SHA1SignatureProvider alloc] init];
    NSString *mac = [provider signClearText:baseString withSecret:key];
    [provider release];
    //return 'MAC id="' + id + '",ts="' + ts + '",nonce="' + nonce + '",mac="' + mac + '"'
    unichar quotes = 0x22;
    NSString *returnString = [NSString stringWithFormat:@"MAC id=%C%@%C,ts=%C%.f%C,nonce=%C%@%C,mac=%C%@%C", quotes, access_token, quotes, quotes, timestamp, quotes, quotes, nonce, quotes, quotes, mac, quotes];
    return returnString; 
}


@end
