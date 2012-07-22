//
//  DealPlaceMark.m
//  GetIt
//
//  Created by Laurent Gaches on 7/22/12.
//  Copyright (c) 2012 GetIt. All rights reserved.
//

#import "DealPlaceMark.h"


@implementation DealPlaceMark

@synthesize coordinate;
@synthesize title;
@synthesize subtitle;
@synthesize googleMapsUrl;

- (id)initWithCoordinate:(CLLocationCoordinate2D)newCoordinate {
    self = [super init];
    if(self != nil) {
        self.coordinate = newCoordinate;
    }
    return self;
}


@end
