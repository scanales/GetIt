//
//  DealPlaceMark.h
//  GetIt
//
//  Created by Laurent Gaches on 7/22/12.
//  Copyright (c) 2012 GetIt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>


@interface DealPlaceMark : NSObject <MKAnnotation> {
    CLLocationCoordinate2D coordinate;
    NSString *title;
    NSString *subtitle;
    NSString *googleMapsUrl;
}

@property(nonatomic, unsafe_unretained) CLLocationCoordinate2D coordinate;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *subtitle;
@property(nonatomic, copy) NSString *googleMapsUrl;

- (id)initWithCoordinate:(CLLocationCoordinate2D)newCoordinate;


@end
