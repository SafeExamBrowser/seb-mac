/*
 Copyright (c) 2008 Matthew Ball - http://www.mattballdesign.com
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

#import "MBPreferencesController.h"
#import "NSWindow+SEBWindow.h"
#import "PreferencesWindow.h"
#import "DropDownButton.h"

NSString *MBPreferencesSelectionAutosaveKey = @"MBPreferencesSelection";

@interface MBPreferencesController (Private) 
- (void)_setupToolbar;
- (void)_selectModule:(NSToolbarItem *)sender;
- (void)_changeToModule:(id<MBPreferencesModule>)module;
@end

@implementation MBPreferencesController

#pragma mark -
#pragma mark Property Synthesis

@synthesize modules=_modules;

#pragma mark -
#pragma mark Life Cycle

- (id)init
{
	if (self == [super init]) {
        [self openWindow];
	}
	return self;
}

- (void)openWindow
{
    if (!self.window) {
        PreferencesWindow *prefsWindow = [[PreferencesWindow alloc] initWithContentRect:NSMakeRect(0, 0, 300, 200) styleMask:(NSTitledWindowMask | NSClosableWindowMask) backing:NSBackingStoreBuffered defer:YES];
        [prefsWindow setReleasedWhenClosed:YES];
        [prefsWindow setShowsToolbarButton:NO];
        //[prefsWindow setLevel:NSModalPanelWindowLevel];
        //[prefsWindow setLevel:NSNormalWindowLevel];
        self.window = prefsWindow;
        [self.window setLevel:NSModalPanelWindowLevel];
        
        [self _setupToolbar];
    }
}

- (void)dealloc
{
	self.modules = nil;
}

- (void)unloadNibs
{
    progressIndicatorHolder = nil;
	self.modules = nil;
    [self.window close];
    self.window = nil;
    [self close];
}

static MBPreferencesController *sharedPreferencesController = nil;

+ (MBPreferencesController *)sharedController
{
	@synchronized(self) {
		if (sharedPreferencesController == nil) {
			id __unused unusedSPC = [[self alloc] init]; // assignment not done here, suppress "unused" warning
		}
	}
	return sharedPreferencesController;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self) {
		if (sharedPreferencesController == nil) {
			sharedPreferencesController = [super allocWithZone:zone];
			return sharedPreferencesController;
		}
	}
	return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}
/* We are using GC
- (id)retain
{
	return self;
}

- (unsigned)retainCount
{
	return UINT_MAX; // denotes an object that cannot be released
}

- (void)release
{
	// do nothing
}

- (id)autorelease
{
	return self;
}
*/
#pragma mark -
#pragma mark NSWindowController Subclass

- (void)showWindow:(id)sender
{
    // Set preferences title as module title – settings title
    [self setPreferencesWindowTitle];

    // Send the current module the willBeDisplayed message
    id<MBPreferencesModule> defaultModule = [self _getSelectedModule];

    if ([(NSObject *)defaultModule respondsToSelector:@selector(willBeDisplayed)]) {
        [defaultModule willBeDisplayed];
    }

	[self.window center];
    
    NSPoint topLeftPoint;
    topLeftPoint.x = self.window.frame.origin.x;
    topLeftPoint.y = self.window.screen.frame.size.height - 44;
    
    [self.window setFrameTopLeftPoint:topLeftPoint];
    [self.window setLevel:NSModalPanelWindowLevel];

	[super showWindow:sender];
//    [[NSApplication sharedApplication] runModalForWindow:self.window];
}


#pragma mark -
#pragma mark NSToolbar

- (void)_setupToolbar
{
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"PreferencesToolbar"];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setDelegate:self];
	[toolbar setAutosavesConfiguration:NO];
	[self.window setToolbar:toolbar];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	NSMutableArray *identifiers = [NSMutableArray array];
	for (id<MBPreferencesModule> module in self.modules) {
		[identifiers addObject:[module identifier]];
	}
	
	return identifiers;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	// We start off with no items. 
	// Add them when we set the modules
	return nil;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	id<MBPreferencesModule> module = [self moduleForIdentifier:itemIdentifier];
	
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	if (!module)
		return item;
	
	
	[item setLabel:[module title]];
	[item setImage:[module image]];
	[item setTarget:self];
	[item setAction:@selector(_selectModule:)];
	return item;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}

#pragma mark -
#pragma mark Modules

- (id<MBPreferencesModule>)moduleForIdentifier:(NSString *)identifier
{
	for (id<MBPreferencesModule> module in self.modules) {
		if ([[module identifier] isEqualToString:identifier]) {
			return module;
		}
	}
	return nil;
}

- (void)setModules:(NSArray *)newModules
{
	if (_modules) {
		_modules = nil;
	}
	
	if (newModules != _modules) {
		_modules = newModules;
		
		// Reset the toolbar items
		NSToolbar *toolbar = [self.window toolbar];
		if (toolbar) {
			NSInteger index = [[toolbar items] count]-1;
			while (index > 0) {
				[toolbar removeItemAtIndex:index];
				index--;
			}
			
			// Add the new items
			for (id<MBPreferencesModule> module in self.modules) {
				[toolbar insertItemWithItemIdentifier:[module identifier] atIndex:[[toolbar items] count]];
			}
		}
		
		// Change to the correct module
		if ([self.modules count]) {
            id<MBPreferencesModule> defaultModule = [self _getSelectedModule];
			[self _changeToModule:defaultModule];
		}
	}
}


// Get the last selected module from the preferences autosave info
- (id<MBPreferencesModule>)_getSelectedModule {
    id<MBPreferencesModule> defaultModule = nil;
    // Check the autosave info
    NSString *savedIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:MBPreferencesSelectionAutosaveKey];
    defaultModule = [self moduleForIdentifier:savedIdentifier];
    
    if (!defaultModule) {
        defaultModule = [self.modules objectAtIndex:0];
    }
    
    return defaultModule;
}


- (void)_selectModule:(NSToolbarItem *)sender
{
	if (![sender isKindOfClass:[NSToolbarItem class]])
		return;
	
	id<MBPreferencesModule> module = [self moduleForIdentifier:[sender itemIdentifier]];
	if (!module)
		return;
	
	[self _changeToModule:module];
}

- (void)changeToModuleWithIdentifier:(NSString *)identifier
{
	id<MBPreferencesModule> module = [self moduleForIdentifier:identifier];
	if (!module)
		return;
	
	[self _changeToModule:module];
}

- (void)_changeToModule:(id<MBPreferencesModule>)module
{
   // NSView *currentModuleView = [_currentModule view];
    // Send currently displayed module message that it's about to be hidden
    if (self.window.isVisible && [(NSObject *)_currentModule respondsToSelector:@selector(willBeHidden)]) {
		[_currentModule willBeHidden];
	}
	
	[[_currentModule view] removeFromSuperview];
	
	NSView *newView = [module view];
	
	// Resize the window
	NSRect newWindowFrame = [self.window frameRectForContentRect:[newView frame]];
	newWindowFrame.origin = [self.window frame].origin;
	newWindowFrame.origin.y -= newWindowFrame.size.height - [self.window frame].size.height;
	[self.window setFrame:newWindowFrame display:YES animate:YES];
	
	[[self.window toolbar] setSelectedItemIdentifier:[module identifier]];

	if ([(NSObject *)module respondsToSelector:@selector(willBeDisplayed)]) {
		[module willBeDisplayed];
	}
	
	_currentModule = module;
	[[self.window contentView] addSubview:[_currentModule view]];
	
    // Set preferences title as module title – settings title
    [self setPreferencesWindowTitle];
	
	// Autosave the selection
	[[NSUserDefaults standardUserDefaults] setObject:[module identifier] forKey:MBPreferencesSelectionAutosaveKey];
}

- (void)setPreferencesWindowTitle
{
    // Set preferences title as module title – settings title
//    NSString *filename = [self.settingsTitle.lastPathComponent stringByRemovingPercentEncoding];
    [self.window setRepresentedURL:nil];
    NSString *filename;
    if (self.settingsFileURL) {
        filename = self.settingsFileURL.lastPathComponent;
    } else {
        filename = NSLocalizedString(@"Local Client Settings", nil);
    }
	[self.window setTitle:[NSString stringWithFormat:@"%@  —  %@", filename, _currentModule.title]];
    [self.window setRepresentedURL:self.settingsFileURL];
    
    if (!progressIndicatorHolder) {
        progressIndicatorHolder = [[NSView alloc] init];
        
        DropDownButton *triangleDropDownButton = [[DropDownButton alloc] init];
        [triangleDropDownButton setButtonType: NSMomentaryPushInButton];
        [triangleDropDownButton setBezelStyle: NSInlineBezelStyle];
        [triangleDropDownButton setBordered: NO];
        [triangleDropDownButton setImage:[NSImage imageNamed:@"MenuTriangleDown"]];
        [triangleDropDownButton setMenu:self.settingsMenu];
        [triangleDropDownButton sizeToFit];
        [triangleDropDownButton setAction:@selector(dropDownAction:)];
        
        [progressIndicatorHolder addSubview:triangleDropDownButton];
        [progressIndicatorHolder setFrame:triangleDropDownButton.frame];
        
//        [self.window addViewToTitleBar:progressIndicatorHolder atRightOffset:5];
        [self.window addViewToTitleBar:progressIndicatorHolder atRightOffsetToTitle:5 verticalOffset:-2];
        
        [triangleDropDownButton setFrame:NSMakeRect(
                                               
                                               0.5 * ([triangleDropDownButton superview].frame.size.width - triangleDropDownButton.frame.size.width),
                                               0.5 * ([triangleDropDownButton superview].frame.size.height - triangleDropDownButton.frame.size.height),
                                               
                                               triangleDropDownButton.frame.size.width,
                                               triangleDropDownButton.frame.size.height
                                               
                                               )];
        
        [triangleDropDownButton setNextResponder:progressIndicatorHolder];
        [progressIndicatorHolder setNextResponder:self];
    } else {
        [self.window adjustPositionOfViewInTitleBar:progressIndicatorHolder atRightOffsetToTitle:5 verticalOffset:-2];
    }
}

// -------------------------------------------------------------------------------
//	dropDownAction:sender
//
//	User clicked the DropDownButton.
// -------------------------------------------------------------------------------
- (IBAction)dropDownAction:(id)sender
{
	// Drop down button clicked
    DDLogDebug(@"Drop down button clicked. Sender: %@", sender);
}

@end
