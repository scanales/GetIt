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

#if DEBUG
#define SMLog(format, ...) {NSLog(format, ##__VA_ARGS__);}
#define StackMobDebug(format, ...) {NSLog([[NSString stringWithFormat:@"[%s, %@, %d] ", __PRETTY_FUNCTION__, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__] stringByAppendingFormat:format, ##__VA_ARGS__]);}
#else
#define SMLog(format, ...)
#define StackMobDebug(format, ...)
#endif

#define STACKMOB_OAUTH_VERSION      OAuth2
#define STACKMOB_PUBLIC_KEY         @"YOUR_PUBLIC_KEY"
#define STACKMOB_PRIVATE_KEY        @"YOUR_PRIVATE_KEY"
#define STACKMOB_APP_NAME           @"YOUR_APP_NAME"
#define STACKMOB_UDID_SALT          @"YOUR_SALT_HERE"
#define STACKMOB_APP_DOMAIN         @"stackmob.com"
#define STACKMOB_APP_MOB            @"mob1"
#define STACKMOB_USER_OBJECT_NAME   @"user"
#define STACKMOB_API_VERSION        0
