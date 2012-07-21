//
//  SMGeoPoint.h
//  StackMobiOS
//
//  Created by Jordan West on 11/30/11.
//  Copyright (c) 2011 StackMob, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMGeoPoint : NSObject

@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;

+ (id)geoPointWithLongitude:(double)lon andLatitude:(double)lat;

- (id)initWithLongitiude:(double)lon andLatitude:(double)lat;

- (NSArray *)arrayValue;

- (NSString *)stringValue;

@end
