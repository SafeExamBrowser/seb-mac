//
//  ViewController.h
//  SEB
//
//  Created by Daniel R. Schneider on 10/09/15.
//
//

#import <UIKit/UIKit.h>

@interface SEBViewController : UIViewController

@property (strong, nonatomic) UIAlertController *alertController;

- (void)dissmissGuidedAccessAlert;
- (void)startExam;

@end

