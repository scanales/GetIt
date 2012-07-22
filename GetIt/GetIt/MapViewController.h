//
//  MapViewController.h
//  GetIt
//
//  Created by Laurent Gaches on 7/22/12.
//  Copyright (c) 2012 GetIt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MapViewController : UIViewController {
    
    __weak IBOutlet MKMapView *mapView;
}

@property (nonatomic,strong) NSDictionary *item;

- (IBAction)openInMaps:(id)sender;


@end
