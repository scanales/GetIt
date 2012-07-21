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

#import "StackMobAdditions.h"
#import "NSString+URLEncoding.h"

@implementation NSDictionary (StackMobAdditions)

- (NSString*)queryString
{
	NSMutableArray* encodedPieces = [NSMutableArray array];
	
	for(NSString* argumentKey in self){
		id argumentValue = [self objectForKey:argumentKey];
		if(!argumentValue)
			continue;
        
		NSString *preparedArgVal;
        if ([argumentValue isKindOfClass:[NSArray class]]) {
            preparedArgVal = [(NSArray *)argumentValue componentsJoinedByString:@","];
        } else if([argumentValue isKindOfClass:[NSNumber class]]) {
            if(argumentValue == (id)kCFBooleanTrue) {
                preparedArgVal = @"true";
            } else if (argumentValue == (id)kCFBooleanFalse) {
                preparedArgVal = @"false";
            } else {
                preparedArgVal = [argumentValue stringValue];
            }
        } else {
            preparedArgVal = argumentValue;
        }
        
        NSString *escapedKey   = [(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)argumentKey, NULL, CFSTR("?=&+;|"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) autorelease];
		NSString *escapedValue = [(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)preparedArgVal, NULL, CFSTR("?=&+;|"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) autorelease];
		[encodedPieces addObject:[NSString stringWithFormat:@"%@=%@", escapedKey, escapedValue]];
	}
	
	return [encodedPieces componentsJoinedByString:@"&"];
}

- (NSDictionary *)updateCounterForFieldAndReturnDictionary:(NSString *)field by:(int)value
{
    NSMutableDictionary *temp = [[self mutableCopy] autorelease];
    [temp setObject:[NSNumber numberWithInt:value] forKey:[NSString stringWithFormat:@"%@[inc]", field]];
    //NSDictionary *new = [[temp copy] retain];
    return [temp copy];
    
}

@end

@implementation NSMutableDictionary (StackMobAdditions)

- (void)updateCounterForField:(NSString *)field by:(int)value
{
    [self setObject:[NSNumber numberWithInt:value] forKey:[NSString stringWithFormat:@"%@[inc]", field]];
}

@end

@implementation NSArray (StackMobAdditions)

- (BOOL)isEmpty
{
    return self.count == 0;
}

@end
