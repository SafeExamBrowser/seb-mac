//
//  SEBSearchBarControllerViewController.m
//
//  Created by Daniel R. Schneider on 06/01/16.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBSearchBarViewController.h"
#import "Webpages.h"
#import "OpenWebpages.h"

@interface SEBSearchBarViewController ()

@end

@implementation SEBSearchBarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        shouldBeginEditing = YES;

        // Don't ask me why I set these values below, but they work...
        self.searchBar = [[SEBTextField alloc] initWithFrame:CGRectMake(-4.0, 7.0, 560.0, 28.0)];
        self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 552.0, 44.0)];
        searchBarView.autoresizingMask = 0;
        [searchBarView setTranslatesAutoresizingMaskIntoConstraints:YES];
        
        self.searchBar.borderStyle = UITextBorderStyleRoundedRect;
        self.searchBar.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25];
        self.searchBar.font = [UIFont systemFontOfSize:16];

//        self.searchBar.showsCancelButton = NO;
        self.searchBar.returnKeyType = UIReturnKeyGo;
        self.searchBar.placeholder = NSLocalizedString(@"Search or enter URL", @"Placeholder text in URL and search bar");
        self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
//        [self.searchBar setImage:[UIImage imageNamed:@"Reload"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
        
        reloadButtonImage = [UIImage imageNamed:@"Reload"];
        stopLoadingButtonImage = [UIImage imageNamed:@"Cancel"];
        
        UIButton *reloadButton = [UIButton buttonWithType:UIButtonTypeSystem]; //[UIButton buttonWithType:UIButtonTypeCustom];
        reloadButton.frame = CGRectMake(0, 0, 16, 16);
        reloadButton.backgroundColor = [UIColor clearColor];
        [reloadButton setImage:reloadButtonImage forState:UIControlStateNormal];//your button image.
        reloadButton.contentMode = UIViewContentModeCenter;
        [reloadButton addTarget:self action:@selector(reloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];//This is the custom event
        self.searchBarRightButton = reloadButton;
        [self.searchBar setRightView:reloadButton];
        [self.searchBar setRightViewMode:UITextFieldViewModeUnlessEditing];

        self.searchBar.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        //[self.searchBar setRightView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Reload"]]];
        //    [searchBar setImage:[UIImage imageNamed:@"Reload"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateSelected];
//        self.searchBar.showsBookmarkButton = NO;

//        self.searchBar.clearButtonMode = UITextFieldViewModeNever;

//        self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
        //[searchBar setShowsCancelButton:YES animated:YES];
        self.searchBar.delegate = self;
        [searchBarView addSubview:self.searchBar];
        self.view = searchBarView;
        
        // Add an observer for the request to reload webpage
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(switchToTab:)
                                                     name:@"requestWebpageReload" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setLoading:(BOOL)loading
{
    if (self.searchBar.text.length > 0) {
        if (loading) {
            [self.searchBarRightButton setImage:stopLoadingButtonImage forState:UIControlStateNormal];//your button image.
        } else {
            [self.searchBarRightButton setImage:reloadButtonImage forState:UIControlStateNormal];//your button image.
        }
    } else {
        [self.searchBarRightButton setImage:nil forState:UIControlStateNormal];
    }
}

- (void)setUrl:(NSString *)url
{
    self.searchBar.text = url;
    
    if (url && url.length > 0)
    {
        // Create blank search bar "Search" (magnifier glass) icon
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0.0);
//        UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
//        [self.searchBar setImage:blank forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
//        [self.searchBar setPositionAdjustment:UIOffsetMake(-20, 0) forSearchBarIcon:UISearchBarIconSearch];

        //    UIOffset searchTextOffset = UIOffsetMake(-20, 0);
        //    [self.searchBar setSearchTextPositionAdjustment:searchTextOffset];
        
        // hide magnifying glass
        //    UITextField* searchField = nil;
        //    for (UIView* subview in self.view.subviews) {
        //        if ([subview isKindOfClass:[UITextField class]]) {
        //            searchField = (UITextField*)subview;
        //            break;
        //        }
        //    }
        //    if (searchField) {
        //        searchField.leftViewMode = UITextFieldViewModeNever;
        //    }
        if (!self.searchBar.rightView) {
            [self.searchBar setRightView:self.searchBarRightButton];
        }
        [self setLoading:NO];

    } else {
        [self.searchBar setRightView:nil];
//        [self.searchBar setImage:UISearchBarIconSearch forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
//        [self.searchBar setPositionAdjustment:UIOffsetMake(0, 0) forSearchBarIcon:UISearchBarIconSearch];
    }
}


// It was switched to new tab: Display new page URL in the search field
- (void)switchToTab:(id)sender {
    NSUInteger tabIndex = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow;
    Webpages *webpage = self.browserTabViewController.persistentWebpages[tabIndex];
    self.url = webpage.url;

}


- (void)reloadButtonPressed
{
    if (self.loading) {
        [self.browserTabViewController stopLoading];
    } else {
        [self.browserTabViewController reload];
    }
}


-(void)cancelButtonPressed
{
    NSString *searchString = self.searchBar.text;
    
    if (searchString.length == 0) {
        if (self.searchBar.rightView) {
            self.searchBar.rightView = nil;
        }
    } else {
        if (!self.searchBar.rightView) {
            [self.searchBar setRightView:self.searchBarRightButton];
        }
    }

    [self.searchBar resignFirstResponder];
}


#pragma mark -
#pragma mark UISearchBarDelegate


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
//    [self.rootViewController searchStarted];
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
//    [self.rootViewController searchStopped];
}


- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (self.searchBar.rightView) {
        self.searchBar.rightView = nil;
    }
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    NSString *searchString = self.searchBar.text;
    
    [self.searchBar resignFirstResponder];

//    [self.rootViewController searchGoSearchString:searchString];

    return YES;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    NSString *searchString = [NSString stringWithString:[textField.text stringByReplacingCharactersInRange:range withString:string]];
    
    if (searchString.length == 0) {
        if (self.searchBar.rightView) {
            self.searchBar.rightView = nil;
        }
    } else {
        if (!self.searchBar.rightView) {
            [self.searchBar setRightView:self.searchBarRightButton];
        }
    }
//
//    NSPredicate *filter      = [NSPredicate predicateWithFormat:@"CONTAINS[cd] %@", searchString];
//    resultArray              = [[resultTempArray filteredArrayUsingPredicate:filter] mutableCopy];
//    
//    if (!searchString || searchString.length == 0) {
//        
//        resultArray          = [resultTempArray mutableCopy];
//    }
//    else{
//        
//        if (resultArray.count == 0) {
//            
//            // No records
//        }
//    }    
//    
//    [tableView reloadData];    
    
    return YES;    
}


//- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
//    NSLog(@"searchBarTextDidBeginEditing");
//    
//    // Create blank search bar "Search" (magnifier glass) icon
//    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0.0);
//    UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
////    [self.searchBar setImage:blank forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
////    [self.searchBar setPositionAdjustment:UIOffsetMake(-20, 0) forSearchBarIcon:UISearchBarIconSearch];
//}
//
//
//- (void)searchBar:(UISearchBar *)bar textDidChange:(NSString *)searchText {
//    NSLog(@"searchBar:textDidChange: isFirstResponder: %i", [self.searchBar isFirstResponder]);
//    if(![self.searchBar isFirstResponder]) {
//        // User taped the reload button
//        shouldBeginEditing = NO;
////        [self.searchBar setImage:[UIImage imageNamed:@"Cancel"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
//        [self.webViewController reload];
//    } else {
//        // User tapped the clear button
//        [self setUrl:@""];
//    }
//}
//
//
//- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
//    // reset the shouldBeginEditing BOOL ivar to YES, but first take its value and use it to return it from the method call
//    BOOL boolToReturn = shouldBeginEditing;
//    shouldBeginEditing = YES;
//    return boolToReturn;
//}

@end
