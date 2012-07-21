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

#import "StackMobConfiguration.h"
#import "JSONKit.h"

#define DEVICE_TAG_NAME						@"u"			
#define DEVICE_NAME							@"dn"	
#define DEVICE_TYPE_NAME					@"dt"	
#define DEVICE_OS_VERSION_NAME				@"ov"	
#define DEVICE_COUNTRY_CODE					@"c"	
#define DEVICE_LANGUAGE						@"l"
#define DEVICE_IS_JAILBORKEN				@"j"			
#define APP_VERSION_NAME					@"av"	
#define LIBRARY_VERSION_NAME				@"lv"
#define NETWORK_AVAILABILITY				@"n"
#define LIBRARY_VERSION_NUMBER				@"0.5"	

#define IFPGA_NAMESTRING					@"iFPGA"

#define IPHONE_1G_NAMESTRING				@"iPhone 1G"
#define IPHONE_3G_NAMESTRING				@"iPhone 3G"
#define IPHONE_3GS_NAMESTRING				@"iPhone 3GS" 
#define IPHONE_4_NAMESTRING					@"iPhone 4" 
#define IPHONE_5_NAMESTRING					@"iPhone 5"
#define IPHONE_UNKNOWN_NAMESTRING			@"Unknown iPhone"

#define IPOD_1G_NAMESTRING					@"iPod touch 1G"
#define IPOD_2G_NAMESTRING					@"iPod touch 2G"
#define IPOD_3G_NAMESTRING					@"iPod touch 3G"
#define IPOD_4G_NAMESTRING					@"iPod touch 4G"
#define IPOD_UNKNOWN_NAMESTRING				@"Unknown iPod"

#define IPAD_1G_NAMESTRING					@"iPad 1G"
#define IPAD_2G_NAMESTRING					@"iPad 2G"
#define IPAD_UNKNOWN_NAMESTRING				@"Unknown iPad"

#define APPLETV_2G_NAMESTRING				@"Apple TV 2G"

#define IPOD_FAMILY_UNKNOWN_DEVICE			@"Unknown iOS device"

#define IPHONE_SIMULATOR_NAMESTRING			@"iPhone Simulator"
#define IPHONE_SIMULATOR_IPHONE_NAMESTRING	@"iPhone Simulator"
#define IPHONE_SIMULATOR_IPAD_NAMESTRING	@"iPad Simulator"

@interface StackMobClientData : NSObject {
	NSString *_clientDataString;
}

@property(readwrite, retain) NSString *clientDataString;


+ (StackMobClientData*) sharedClientData;
- (BOOL) isJailBroken;
- (NSString*) isJailBrokenStr;

@end
