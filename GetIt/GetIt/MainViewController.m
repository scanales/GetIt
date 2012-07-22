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
    return [items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DealCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    NSDictionary *item = [items objectAtIndex:indexPath.row];
    
    NSDictionary *deal = [item objectForKey:@"deal"];
    
    UILabel *textLabel = (UILabel *)[cell viewWithTag:2];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    
    textLabel.font = [UIFont fontWithName:@"Futura-Medium" size:14.];
    textLabel.text = [NSString stringWithFormat:@"%@",[deal objectForKey:@"title"]];
    
    [imageView setImageWithURL:[NSURL URLWithString:[deal objectForKey:@"image_thumb_retina"]]];
    
    
    
    return cell;
}

#pragma mark - Table view delegate



-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString: @"dealDetail"]) {
        //pass values
        NSLog(@"The sender is %@",sender);
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        
        DealDetailViewController *dest = [segue destinationViewController];
        dest.item = [items objectAtIndex:indexPath.row];
       
    }
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
        
        [self.tableView reloadData];
//        NSLog(@"DEALS %@",[[[[JSON objectForKey:@"items"] lastObject] objectForKey:@"merchant"] class]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"ERROR : %@ \n",error.localizedDescription);
    }];
    
    
    [reqOp start];
    
}


@end
