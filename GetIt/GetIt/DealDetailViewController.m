//
//  DealDetailViewController.m
//  GetIt
//
//  Created by Laurent Gaches on 7/21/12.
//  Copyright (c) 2012 GetIt. All rights reserved.
//

#import "DealDetailViewController.h"
#import "AFNetworking.h"

@interface DealDetailViewController ()

@end


@implementation DealDetailViewController

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
    
    NSDictionary *deal = [item objectForKey:@"deal"];
    [illustration setImageWithURL:[NSURL URLWithString:[deal objectForKey:@"image"]]];
    [self setTitle:[deal objectForKey:@"title"]];
    
    titleLbl.text = [deal objectForKey:@"title"];
    discount.text = [deal objectForKey:@"discount"];
    [addresslbl setText:[[item objectForKey:@"merchant"] objectForKey:@"address"]];
    [self.view addSubview:address];
    
    
}

- (void)viewDidUnload
{
    discount = nil;
    illustration = nil;
    titleLbl = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
