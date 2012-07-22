//
//  DealDetailViewController.h
//  GetIt
//
//  Created by Laurent Gaches on 7/21/12.
//  Copyright (c) 2012 GetIt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DealDetailViewController : UIViewController {
    
    __weak IBOutlet UILabel *descriptionLbl;
    __weak IBOutlet UIImageView *illustration;
    __weak IBOutlet UILabel *discount;
    __weak IBOutlet UILabel *titleLbl;
}

@property (nonatomic,strong) NSDictionary *item;

@end
