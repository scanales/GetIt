//
//  DealDetailViewController.m
//  GetIt
//
//  Created by Laurent Gaches on 7/21/12.
//  Copyright (c) 2012 GetIt. All rights reserved.
//

#import "DealDetailViewController.h"
#import "AFNetworking.h"
#import "MapViewController.h"

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
    addressLbl.text= [[item objectForKey:@"merchant"] objectForKey:@"address"];
    
    
    descriptionTextView.text = [deal objectForKey:@"description"];

    
}

- (void)viewDidUnload
{
    discount = nil;
    illustration = nil;
    titleLbl = nil;
    addressLbl = nil;
    descriptionTextView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString: @"mapView"]) {
        MapViewController *dest = [segue destinationViewController];        
        dest.item = self.item;
    }
}

#pragma mark - Actions

- (IBAction)scanCard:(id)sender {
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
    scanViewController.appToken = @"9b39146fbf8a4ff4aa9b65cb72dbd1f7"; // get your app token from the card.io website
    [self presentModalViewController:scanViewController animated:YES];
}

- (IBAction)holdItAction:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"We will hold it for 30 minutes under this name." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok",nil ];
    
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    [alert show];
}


#pragma mark - CardIOPaymentViewControllerDelegate

- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)scanViewController {
    NSLog(@"User canceled payment info");
    // Handle user cancellation here...
    [scanViewController dismissModalViewControllerAnimated:YES];
}

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)info inPaymentViewController:(CardIOPaymentViewController *)scanViewController {
    // The full card number is available as info.cardNumber, but don't log that!
    NSLog(@"Received card info. Number: %@, expiry: %02i/%i, cvv: %@.", info.redactedCardNumber, info.expiryMonth, info.expiryYear, info.cvv);
    // Use the card info...
    [scanViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"We'll reserve your deal for 30 minutes. See you soon." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
}


@end
