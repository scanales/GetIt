//
//  ViewController.m
//  GetIt
//
//  Created by Laurent Gaches on 7/21/12.
//  Copyright (c) 2012 GetIt. All rights reserved.
//

#import "MainViewController.h"
#import "DealDetailViewController.h"
#import "AFNetworking.h"
#import "JSONKit.h"

@interface MainViewController ()

@end

@implementation MainViewController

CLLocationManager *locationManager;
CLLocation *userLocation;


NSMutableArray *items;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    if (nil == locationManager) {
        locationManager = [[CLLocationManager alloc] init];
        
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        //locationManager.distanceFilter = 500;
        [locationManager startUpdatingLocation];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    cell.textLabel.text = [NSString stringWithFormat:@"Deal %d",indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIStoryboard *storyboard = self.storyboard;
    
    DealDetailViewController *detailViewController = [storyboard instantiateViewControllerWithIdentifier:@"dealDetail"];
    
    [self.navigationController pushViewController:detailViewController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (void)sortItems:(NSMutableArray *)items{
    NSLog(@"Sorting");
    NSLog(@"%@", items);
    int RADIUS = 6371; //earth's radius
    for (NSMutableDictionary *d in items) {
        NSDictionary *merch = [d objectForKey: @"merchant"];
        float lat = [[merch objectForKey:@"latitude"] floatValue];
        float lon = [[merch objectForKey:@"longitude"] floatValue];
        
        float latDiff = ((lat - userLocation.coordinate.latitude) * M_PI) / 180;
        float lonDiff = ((lon - userLocation.coordinate.longitude) * M_PI) / 180;
        
        float a = sinf(latDiff/2) * sinf(latDiff/2) + sinf(lonDiff/2) * sinf(lonDiff/2) * cosf(lat) * cos(userLocation.coordinate.latitude);
        
        float c = 2 * atan2f(sqrtf(a), sqrtf(1-a));
        
        float distance = RADIUS * c;

        
        NSLog(@"DISTANCE:\n%f", distance);
        [d setObject: [NSNumber numberWithFloat: distance] forKey:@"distance"];
    }
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"distance"  ascending:YES];

    [items sortUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
    
    NSLog(@"%@", items);
    
    
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    

    
    NSLog(@" lat :%f  long: %f",newLocation.coordinate.latitude,newLocation.coordinate.longitude);
    userLocation = newLocation;

    [locationManager stopUpdatingLocation];

    //http://lesserthan.com/api.getDealsLatLon/json/?lat=40.4427&lon=-80.0120
    
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://lesserthan.com/api.getDealsLatLon/json/?lat=%f&lon=%f",userLocation.coordinate.latitude,userLocation.coordinate.longitude]]];
    
    AFHTTPRequestOperation *reqOp = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [reqOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
        NSLog(@"class %@",[responseObject class]);
        JSONDecoder *decoder = [[JSONDecoder alloc] init];
        id JSON = [decoder mutableObjectWithData:responseObject];
        items = [JSON objectForKey:@"items"];
        [self sortItems:items];
//        NSLog(@"DEALS %@",[[[[JSON objectForKey:@"items"] lastObject] objectForKey:@"merchant"] class]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"ERROR : %@ \n",error.localizedDescription);
    }];
    
    
    [reqOp start];
    
}


@end
