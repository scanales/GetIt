//
//  MapViewController.m
//  GetIt
//
//  Created by Laurent Gaches on 7/22/12.
//  Copyright (c) 2012 GetIt. All rights reserved.
//

#import "MapViewController.h"
#import "DealPlaceMark.h"

@interface MapViewController ()

@end

@implementation MapViewController

@synthesize item;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    CLLocationCoordinate2D coordinate = {[[[item objectForKey:@"merchant"] objectForKey:@"latitude"] doubleValue],[[[item objectForKey:@"merchant"] objectForKey:@"longitude"] doubleValue]};
    DealPlaceMark *placeMark = [[DealPlaceMark alloc] initWithCoordinate:coordinate];
    [placeMark setTitle:[[item objectForKey:@"merchant"] objectForKey:@"name"]];
    
    [mapView addAnnotation:placeMark];
    
    MKCoordinateRegion region;
    region.center = placeMark.coordinate;
	MKCoordinateSpan span;
	span.latitudeDelta = .030;
	span.longitudeDelta = .030;
	region.span = span;
	
	[mapView setRegion:region animated:YES];

}

- (void)viewDidUnload
{
    mapView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)openInMaps:(id)sender {
    NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?ll=%@,%@&z=16",[[item objectForKey:@"merchant"] objectForKey:@"latitude"],[[item objectForKey:@"merchant"] objectForKey:@"longitude"]];

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}


@end
