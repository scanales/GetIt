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

#import "StackMobPushRequest.h"
#import "StackMob.h"

@implementation StackMobPushRequest

+ (id)requestForMethod:(NSString*)method {
    StackMobRequest *r = [[[StackMobPushRequest alloc] init] autorelease];
    r.httpMethod = [self stringFromHttpVerb:POST];
    r.method = method;
    return r;
}

+ (id)requestForMethod:(NSString*)method withArguments:(NSDictionary*)arguments {
    StackMobRequest *r = [[[StackMobPushRequest alloc] init] autorelease];
    r.httpMethod = [self stringFromHttpVerb:POST];
    r.method = method;
    if(arguments != nil) {
        [r setArguments: arguments];
    }
    return r;
}

- (BOOL) useOAuth2 {
    return false;
}

- (NSString *)getBaseURL {
    return [[session pushURL] stringByAppendingFormat:@"/%@", self.method];
}

@end
