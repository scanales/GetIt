//
//  SMFile.m
//  StackMobiOS
//
//  Created by Ryan Connelly on 12/13/11.
//  Copyright (c) 2011 StackMob, Inc. All rights reserved.
//

#import "SMFile.h"
#import "NSData+Base64.h"

@implementation SMFile
@synthesize data;
@synthesize name;
@synthesize contentType;

- (id) initWithFileName:(NSString *)name_ data:(NSData *)data_ contentType:(NSString *)contentType_
{
    self = [super init];
    if(self)
    {
        data = [data_ retain];
        name = [name_ retain];
        contentType = [contentType_ retain];
    }
    return self;
}

+ (id) fileWithName:(NSString *)name_ data:(NSData *)data_ contentType:(NSString *)contentType_
{
    SMFile *file = [[SMFile alloc] initWithFileName:name_ data:data_ contentType:contentType_];
    return [file autorelease];
}

- (id)JSON
{
    return [NSString stringWithFormat:@"Content-Type: %@\n"
            "Content-Disposition: attachment; filename=%@\n"
            "Content-Transfer-Encoding: %@\n\n"
            "%@",
            self.contentType,
            self.name,
            @"base64",
            [self.data base64EncodedString]];
}

- (void)dealloc {
    [data release];
    [name release];
    [contentType release];
    [super dealloc];
}
@end
