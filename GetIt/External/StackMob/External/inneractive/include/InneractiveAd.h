//
//  InneractiveAd.h
//	InneractiveAdSDK
//
//  Created by Inneractive LTD.
//  Copyright 2011 Inneractive LTD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*
 * IaAdType enumeration
 *
 * IaAdType_Banner		- Banner only ad
 * IaAdType_Text		- Text only ad
 * IaAdType_FullScreen	- Full screen ad
 */
typedef enum {
	IaAdType_Banner = 1,
	IaAdType_Text,
	IaAdType_FullScreen
} IaAdType;

/*
 * IaOptionalParams
 *
 * Key_Age				- User's age
 * Key_Distribution_Id	- Distribution channel ID  (iPhone & iPod touch - 642 for banner ads and full screen ads, 632 for text ads
 *													iPad - 947 for banner ads and full screen ads, 946 for text ads)
 * Key_External_Id		- An application specific ID - the ID of the requesting device in the partner's domain
 * Key_Gender			- User's gender (allowed values: M, m, F, f, Male, Female)
 * Key_Gps_Coordinates	- GPS ISO code location data in latitude,longitude format. For example: 53.542132,-2.239856 (w/o spaces)
 * Key_Keywords			- Keywords relevant to this user's specific session (comma separated)
 * Key_Location			- Comma separted list of country,state/province,city. For example: US,NY,NY (w/o spaces)
 * Key_Msisdn			- User's mobile number (MSISDN format, with international prefix)
 */
typedef enum {
	Key_Age = 1,
	Key_Distribution_Id,
	Key_External_Id,
	Key_Gender,
	Key_Gps_Coordinates,
	Key_Keywords,
	Key_Location,
	Key_Msisdn
} IaOptionalParams;

@interface InneractiveAd : NSObject {
}

/*
 * DisplayAd function displays an ad
 *
 * (NSString*)appId		Application ID - provided by inneractive at the application registration
 * (IaAdType)adType		Ad type - can be banner only, text only, or full screen ad
 * (UIView*)root		Root view - the view in which the ad will be displayed
 * (int)reloadTime		Reload time - the ad refresh time (not relevant for a full screen ad)
 *
 * Returns YES if succeeded, or NO if failed
 * Can fail in the following cases:
 *  - No network connection available
 *  - appId is null or an empty string
 *  - root is null
 */
+ (BOOL)DisplayAd:(NSString*)appId withType:(IaAdType)adType withRoot:(UIView*)root withReload:(int)reloadTime;

/*
 * DisplayAd function displays an ad
 *
 * (NSString*)appId							Application ID - provided by inneractive at the application registration
 * (IaAdType)adType							Ad type - can be banner only, text only, or full screen ad
 * (UIView*)root							Root view - the view in which the ad will be displayed
 * (int)reloadTime							Reload time - the ad refresh time (not relevant for a full screen ad)
 * (NSMutableDictionary*)optionalParams		Optional parameters for the ad request
 *
 * Returns YES if succeeded, or NO if failed
 * Can fail in the following cases:
 *  - No network connection available
 *  - appId is null or an empty string
 *  - root is null
 */
+ (BOOL)DisplayAd:(NSString*)appId withType:(IaAdType)adType withRoot:(UIView*)root withReload:(int)reloadTime withParams:(NSMutableDictionary*)optionalParams;

@end