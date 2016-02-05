//
//  SEBWebViewController.m
//
//  Created by Daniel R. Schneider on 06/01/16.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider,
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBWebViewController.h"
#import "UIWebView+SEBWebView.h"
#import "Constants.h"


@interface SEBWebViewController () {

@private
    BOOL allowSpellCheck;
}

@end


@implementation SEBWebViewController


- (void)loadView
{
    // Create a webview to fit underneath the navigation view (=fill the whole screen).
    CGRect webFrame = [[UIScreen mainScreen] applicationFrame];
    if (!_sebWebView) {
        _sebWebView = [[UIWebView alloc] initWithFrame:webFrame];
    }
    _sebWebView.backgroundColor = [UIColor lightGrayColor];
    _sebWebView.scalesPageToFit = YES;
    _sebWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _sebWebView.scrollView.scrollEnabled = YES;
    [_sebWebView setTranslatesAutoresizingMaskIntoConstraints:YES];
    _sebWebView.delegate = self;
    self.view = _sebWebView;
}


- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if (parent) {
        // Add the view to the parent view and position it if you want
        [[parent view] addSubview:self.view];
        CGRect viewFrame = parent.view.bounds;
        //viewFrame.origin.y += kNavbarHeight;
        //viewFrame.size.height -= kNavbarHeight;
        [self.view setFrame:viewFrame];
    } else {
        [self.view removeFromSuperview];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Adjust scroll position so top of webpage is below the navigation bar
//    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
//    CGFloat toolBarHeight = self.navigationController.toolbar.frame.size.height;
//    [self.visibleWebView.scrollView setContentInset:UIEdgeInsetsMake(navBarHeight, 0, toolBarHeight, 0)];
//    [self.visibleWebView.scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(navBarHeight, 0, toolBarHeight, 0)];
//    [self.visibleWebView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _sebWebView.delegate = self;	// setup the delegate as the web view is shown
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    allowSpellCheck = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSpellCheck"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.sebWebView stopLoading];	// in case the web view is still loading its content
    self.sebWebView.delegate = nil;	// disconnect the delegate as the webview is hidden
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_browserTabViewController setLoading:NO];
}

#pragma mark -
#pragma mark Controller interface

- (void)goBack {
    [_sebWebView goBack];
}

- (void)goForward {
    [_sebWebView goForward];
}

- (void)reload {
    [_sebWebView reload];
}

- (void)stopLoading {
    [_sebWebView stopLoading];
}


- (void)loadURL:(NSURL *)url
{
    [self.sebWebView loadRequest:[NSURLRequest requestWithURL:url]];
}


#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    // starting the load, show the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    [self.searchBarController setLoading:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Adjust scroll position so top of webpage is below the navigation bar
//    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
//    CGFloat toolBarHeight = self.navigationController.toolbar.frame.size.height;
//    [webView.scrollView setContentInset:UIEdgeInsetsMake(navBarHeight, 0, toolBarHeight, 0)];
//    [webView.scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(navBarHeight, 0, toolBarHeight, 0)];
//    [webView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    
    // Get JavaScript code for modifying targets of hyperlinks in the webpage so can be open in new tabs
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ModifyPages" ofType:@"js"];
    jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    [_sebWebView stringByEvaluatingJavaScriptFromString:jsCode];
    
    [_sebWebView stringByEvaluatingJavaScriptFromString:@"SEB_ModifyLinkTargets()"];
    [_sebWebView stringByEvaluatingJavaScriptFromString:@"SEB_ModifyWindowOpen()"];
    
    [_sebWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"SEB_AllowSpellCheck(%@)", allowSpellCheck ? @"true" : @"false"]];
    
    //[webView stringByEvaluatingJavaScriptFromString:@"SEB_increaseMaxZoomFactor()"];
    
    //[self highlightAllOccurencesOfString:@"SEB" inWebView:webView];
    //[self speakWebView:webView];
    
    NSString *webPageTitle = [_sebWebView title];
    if ([webPageTitle isEqualToString:@""]) {
        
    } else {
        MainWebView.title = webPageTitle;
    }
    
    // finished loading, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_browserTabViewController setLoading:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // load error, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_browserTabViewController setLoading:NO];
    
    // report the error inside the webview
    NSString* errorString = [NSString stringWithFormat:
                             @"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",
                             error.localizedDescription];
    [webView loadHTMLString:errorString baseURL:nil];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType) __unused navigationType
{
    if (UIAccessibilityIsGuidedAccessEnabled()) {
        if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
            navigationType = UIWebViewNavigationTypeOther;
            DDLogVerbose(@"%s: navigationType changed to UIWebViewNavigationTypeOther", __FUNCTION__);
            [webView loadRequest:request];
            return NO;
        }
    }

    NSURL *url = [request URL];
    if ([[url scheme] isEqualToString:@"newtab"]) {
        NSString *urlString = [[url resourceSpecifier] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        url = [NSURL URLWithString:urlString relativeToURL:[webView url]];
        [_browserTabViewController openNewTabWithURL:url];
        return NO;
    }
    if ([[url scheme] isEqualToString:@"about"]) {
        return NO;
    }
    
    // Check if this is a seb:// or sebs:// link
    if ([url.scheme isEqualToString:@"seb"] || [url.scheme isEqualToString:@"sebs"]) {
        // If the scheme is seb:// we (conditionally) download and open the linked .seb file
        [_browserTabViewController downloadAndOpenSEBConfigFromURL:url];
        return NO;
    }

    // Check if quit URL has been clicked (regardless of current URL Filter)
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([[url absoluteString] isEqualToString:[preferences secureStringForKey:@"org_safeexambrowser_SEB_quitURL"]]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestQuitWPwdNotification" object:self];
        return NO;
    }

    // Downloading image files for the freehand drawing functionality
    if(navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeOther) {
        NSString *fileExtension = [url pathExtension];
        
        if ([fileExtension isEqualToString:@"png"] || [fileExtension isEqualToString:@"jpg"] || [fileExtension isEqualToString:@"tif"] || [fileExtension isEqualToString:@"xls"]) {
            // Get the filename of the loaded ressource form the UIWebView's request URL
            NSString *filename = [url lastPathComponent];
            NSLog(@"Filename: %@", filename);
            // Get the path to the App's Documents directory
            NSString *docPath = [self documentsDirectoryPath];
            // Combine the filename and the path to the documents dir into the full path
            NSString *pathToDownloadTo = [NSString stringWithFormat:@"%@/%@", docPath, filename];
            
            
            // Load the file from the remote server
            NSData *tmp = [NSData dataWithContentsOfURL:url];
            // Save the loaded data if loaded successfully
            if (tmp != nil) {
                NSError *error = nil;
                UIImage *sourceImage = [UIImage imageWithData: [NSData dataWithContentsOfURL:url]];
//                UIImage* flippedImage = [UIImage imageWithCGImage:sourceImage.CGImage
//                                                            scale:sourceImage.scale
//                                                      orientation:UIImageOrientationUpMirrored];
                UIImage *processedImage = [self invertImage:sourceImage];
                NSData *dataForPNGFile = UIImagePNGRepresentation(processedImage);

                // Write the contents of our tmp object into a file
                [dataForPNGFile writeToFile:pathToDownloadTo options:NSDataWritingAtomic error:&error];
                if (error != nil) {
                    NSLog(@"Failed to save the file: %@", [error description]);
                } else {
                    NSString *base64PNGData = [dataForPNGFile base64EncodedStringWithOptions:0];
                    NSString *simulateDropFunction = [NSString stringWithFormat:@"SEB_replaceImage('%@')", base64PNGData];
//                    NSString *result =[_sebWebView stringByEvaluatingJavaScriptFromString:simulateDropFunction];
//                    NSString *result = [_sebWebView stringByEvaluatingJavaScriptFromString:@"SEB_replaceImage()"];
                    // Display an UIAlertView that shows the users we saved the file :)
                    NSURL *drawingURL = [NSURL URLWithString:[NSString stringWithFormat:@"drawing://%@", pathToDownloadTo]];
                    [_browserTabViewController openNewTabWithURL:drawingURL image:processedImage];
//                    UIAlertView *filenameAlert = [[UIAlertView alloc] initWithTitle:@"File saved" message:[NSString stringWithFormat:@"The file %@ has been saved. Result: %@", filename, result] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                    [filenameAlert show];
                    return NO;
                }
            } else {
                // File could notbe loaded -> handle errors
            }
        } else {
            // File type not supported
        }

    }
    return YES;
}


- (UIImage *)invertImage:(UIImage *)originalImage
{
    UIGraphicsBeginImageContext(originalImage.size);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeCopy);
    CGRect imageRect = CGRectMake(0, 0, originalImage.size.width, originalImage.size.height);
    [originalImage drawInRect:imageRect];
    
    
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeDifference);
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, originalImage.size.height);
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    //mask the image
    CGContextClipToMask(UIGraphicsGetCurrentContext(), imageRect,  originalImage.CGImage);
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(),[UIColor whiteColor].CGColor);
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, originalImage.size.width, originalImage.size.height));
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return returnImage;
}

- (NSInteger)highlightAllOccurencesOfString:(NSString*)searchString inWebView:(UIWebView *)webView
{
    //    NSString *path = [[NSBundle mainBundle] pathForResource:@"SearchWebView" ofType:@"js"];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SearchWebView" ofType:@"js"];
    NSString *jsCodeSearch = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [webView stringByEvaluatingJavaScriptFromString:jsCodeSearch];
    
    NSString *startSearch = [NSString stringWithFormat:@"MyApp_HighlightAllOccurencesOfString('%@')", searchString];
    [webView stringByEvaluatingJavaScriptFromString:startSearch];
    
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:@"MyApp_SearchResultCount"];
    return [result integerValue];
}


- (void)removeAllHighlightsInWebView:(UIWebView *)webView
{
    [webView stringByEvaluatingJavaScriptFromString:@"MyApp_RemoveAllHighlights()"];
}

    
- (void)loadWebPageOrSearchResultWithString:(NSString *)webSearchString
{
    [self loadURL:[NSURL URLWithString:webSearchString]];

}


// Create a UIWebView to hold new webpages
- (UIWebView *)createNewWebView {
    // Create a webview to fit underneath the navigation view (=fill the whole screen).
    CGRect webFrame = [[UIScreen mainScreen] applicationFrame];
    UIWebView *newWebView = [[UIWebView alloc] initWithFrame:webFrame];
    
    newWebView.backgroundColor = [UIColor lightGrayColor];
    newWebView.scalesPageToFit = YES;
    newWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    newWebView.scrollView.scrollEnabled = YES;
    [newWebView setTranslatesAutoresizingMaskIntoConstraints:YES];
    newWebView.delegate = self;
    return newWebView;
}


// Read Info.plist values from bundle
- (id) infoValueForKey:(NSString*)key
{
    if ([[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key])
        return [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key];
    
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
}


- (NSString *)documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return documentsDirectoryPath;
}


@end
