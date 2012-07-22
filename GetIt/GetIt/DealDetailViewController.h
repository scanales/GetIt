//
//  DealDetailViewController.h
//  GetIt
//
//  Created by Laurent Gaches on 7/21/12.
//  Copyright (c) 2012 GetIt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CardIO.h"


@interface DealDetailViewController : UIViewController <CardIOPaymentViewControllerDelegate,UIAlertViewDelegate> {
    
    __weak IBOutlet UILabel *addressLbl;
    __weak IBOutlet UILabel *descriptionLbl;
    __weak IBOutlet UIImageView *illustration;
    __weak IBOutlet UILabel *discount;
    __weak IBOutlet UILabel *titleLbl;
}

@property (nonatomic,strong) NSDictionary *item;
- (IBAction)scanCard:(id)sender;
- (IBAction)holdItAction:(id)sender;
@end
