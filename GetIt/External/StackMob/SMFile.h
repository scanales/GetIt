//
//  SMFile.h
//  StackMobiOS
//
//  Created by Ryan Connelly on 12/13/11.
//  Copyright (c) 2011 StackMob, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMFile : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *contentType;
@property (nonatomic, retain) NSData *data;

- (id) initWithFileName:(NSString *)name_ data:(NSData *)data_ contentType:(NSString *)contentType_;
+ (id) fileWithName:(NSString *)name_ data:(NSData *)data_ contentType:(NSString *)contentType_;
- (id)JSON;

@end
