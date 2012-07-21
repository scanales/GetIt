//
//  StackMobBulkRequest.m
//  StackMobiOS
//
//  Created by Jordan West on 12/1/11.
//  Copyright (c) 2011 StackMob, Inc. All rights reserved.
//

#import "StackMobBulkRequest.h"
#import "JSONKit.h"
#import "NSData+JSON.h"

@implementation StackMobBulkRequest

@synthesize bulkArguments = _bulkArguments;

+ (id)requestForMethod:(NSString *)method withArguments:(NSDictionary *)arguments withHttpVerb:(SMHttpVerb)httpVerb {
    return [StackMobBulkRequest requestForMethod:method withArguments:[NSArray arrayWithObject:arguments]];
}

+ (id)requestForMethod:(NSString *)method withArguments:(NSArray *)arguments {
    StackMobBulkRequest *request = [[[StackMobBulkRequest alloc] init] autorelease];
    request.method = method;
    request.bulkArguments = arguments;
    
    return request;
}

+ (NSData *)JsonifyNSArray:(NSArray *)arr withErrorOutput:(NSError **)error {
    
    static id(^unsupportedClassSerializerBlock)(id) = ^id(id object) {
        if ( [object isKindOfClass:[NSData class]] ) {
            NSString* base64String = [(NSData*)object JSON];
            return base64String;
        }
        else {
            return nil;
        }
    };
    
    NSData * json = [arr JSONDataWithOptions:JKSerializeOptionNone
        serializeUnsupportedClassesUsingBlock:unsupportedClassSerializerBlock
                                        error:error];
    return json;
}

- (id) init {
    self = [super init];
    if (self) {
        self.bulkArguments = [NSArray array];
        self.httpMethod = [StackMobRequest stringFromHttpVerb:POST];
    }
    return self;
}

- (NSData *)postBody {
    NSError* error = nil;
    return [StackMobBulkRequest JsonifyNSArray:self.bulkArguments withErrorOutput:&error];
}

@end
