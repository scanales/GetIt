//
//  SMGeoPoint.m
//  StackMobiOS
//
//  Created by Jordan West on 11/30/11.
//  Copyright (c) 2011 StackMob, Inc. All rights reserved.
//

#import "SMGeoPoint.h"

@implementation SMGeoPoint

@synthesize latitude = _latitude;
@synthesize longitude = _longitude;

+ (id)geoPointWithLongitude:(double)lon andLatitude:(double)lat {
    return [[[SMGeoPoint alloc] initWithLongitiude:lon andLatitude:lat] autorelease];
}

- (id)initWithLongitiude:(double)lon andLatitude:(double)lat {
    self = [super init];
    if (self) {
        self.longitude = lon;
        self.latitude = lat;
    }
    return self;
    
}

- (NSArray *)arrayValue {
    return [NSArray arrayWithObjects:[NSNumber numberWithDouble:self.latitude], [NSNumber numberWithDouble:self.longitude], nil];
}

- (NSString *)stringValue {
    return [[self arrayValue] componentsJoinedByString:@","];
}

@end
