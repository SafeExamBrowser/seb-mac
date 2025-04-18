//
//  SEBDockItem.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 01/10/14.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <UIKit/UIKit.h>

@interface SEBSliderItem : NSObject

@property (strong, nonatomic) NSString *title;

@property (strong, nonatomic) UIImage *icon;

@property (weak, nonatomic) id target;
@property (assign, nonatomic) SEL action;
@property (assign, nonatomic) SEL secondaryAction;

@property (assign, nonatomic) BOOL enabled;


- (id) initWithTitle:(NSString *)newTitle
                icon:(UIImage *)newIcon
              target:(id)newTarget
              action:(SEL)newAction;

- (id) initWithTitle:(NSString *)newTitle
                icon:(UIImage *)newIcon
              target:(id)newTarget
              action:(SEL)newAction
     secondaryAction:(SEL)newSecondaryAction;

@end
