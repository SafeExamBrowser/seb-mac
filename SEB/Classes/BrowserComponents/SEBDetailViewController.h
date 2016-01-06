//
//  SEBDetailViewController.h
//  TellTheWeb
//
//  Created by Daniel R. Schneider on 17/04/14.
//  Copyright (c) 2014 art technologies Schneider & Schneider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SEBDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
