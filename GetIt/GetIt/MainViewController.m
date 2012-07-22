//
//  ViewController.m
//  GetIt
//
//  Created by Laurent Gaches on 7/21/12.
//  Copyright (c) 2012 GetIt. All rights reserved.
//

#import "MainViewController.h"
#import "DealDetailViewController.h"
#import "FilterViewController.h"
#import "AFNetworking.h"
#import "JSONKit.h"
#import "MBProgressHUD.h"

@interface MainViewController ()

@end

@implementation MainViewController



CLLocationManager *locationManager;
CLLocation *userLocation;


NSMutableArray *items;
NSMutableArray *categories;
NSMutableArray *filteredItems;

UIImageView *splash;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    splash = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];
    splash.frame = CGRectMake(0, 0, 320, 480);
    
    [self.view addSubview:splash];
    [MBProgressHUD showHUDAddedTo:splash animated:YES];
    
    
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

#pragma mark - filter

-(void)filterCategoryWith:(NSString *)category {

    filteredItems = [[NSMutableArray alloc] init];
    for (NSDictionary *item in items) {
        if ([[[item objectForKey:@"deal"] objectForKey:@"category"] isEqualToString:category]) {
            [filteredItems addObject:item];
        }
    }
    
    [self.tableView reloadData];
    
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
    
    if (filteredItems) {
        return [filteredItems count];
    } else {
        return [items count];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DealCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    
    NSDictionary *item;
    if (filteredItems) {
         item = [filteredItems objectAtIndex:indexPath.row];
    } else {
        item = [items objectAtIndex:indexPath.row];
    }
    

    
    NSDictionary *deal = [item objectForKey:@"deal"];
    
    UILabel *textLabel = (UILabel *)[cell viewWithTag:2];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    UILabel *distanceLbl = (UILabel *)[cell viewWithTag:3];
    UILabel *cityLbl = (UILabel *)[cell viewWithTag:4];
    
    
    textLabel.font = [UIFont fontWithName:@"Futura-Medium" size:14.];
    textLabel.text = [NSString stringWithFormat:@"%@",[deal objectForKey:@"title"]];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setMaximumFractionDigits:2];
    distanceLbl.text = [[numberFormatter stringFromNumber:[item objectForKey:@"distance"] ] stringByAppendingString: @" miles away"];
    [imageView setImageWithURL:[NSURL URLWithString:[deal objectForKey:@"image_thumb_retina"]]];
    
    cityLbl.text = [[item objectForKey: @"merchant"] objectForKey:@"city"];
    
    return cell;
}

- (void)sortItems:(NSMutableArray *)items{
    NSLog(@"Lat %f", userLocation.coordinate.latitude);
    NSLog(@"Lon %f", userLocation.coordinate.longitude);
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
        
        [d setObject: [NSNumber numberWithFloat: distance] forKey:@"distance"];
    }
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"distance"  ascending:YES];

    [items sortUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
}

- (void) getCategories: (NSArray *)items{
    categories = [[NSMutableArray alloc] init];
    for (NSDictionary *d in items) {
        id cat = [[d objectForKey:@"deal"] objectForKey:@"category"];
        if(![categories containsObject:cat]){
            [categories addObject:cat];
        }
    }
    NSLog(@"Categories\n%@", categories);
}
#pragma mark - Table view delegate



-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString: @"dealDetail"]) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        
        DealDetailViewController *dest = [segue destinationViewController];
        dest.item = [items objectAtIndex:indexPath.row];
       
    } else if ([[segue identifier] isEqualToString:@"dealFilter"]) {
        FilterViewController *dest = [segue destinationViewController];
        dest.categories = categories;
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

        [self sortItems:items];
        [self getCategories:items];
        
        [self.tableView reloadData];

        [MBProgressHUD hideAllHUDsForView:splash animated:YES];
        [splash removeFromSuperview];
        

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"ERROR : %@ \n",error.localizedDescription);
    }];
    
    
    [reqOp start];
    
}


@end
