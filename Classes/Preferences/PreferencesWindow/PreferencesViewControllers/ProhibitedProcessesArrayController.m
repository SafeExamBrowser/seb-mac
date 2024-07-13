//
//  ProhibitedProcessesArrayController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 23.08.20.
//

#import "ProhibitedProcessesArrayController.h"
#import "SEBSettings.h"
#import "ProcessManager.h"


@interface ProhibitedProcessesArrayController () {
    NSArray *defaultProhibitedProcesses;
}

@end

@implementation ProhibitedProcessesArrayController

-(id) newObject {
    NSDictionary *newObject = [super newObject];
    newObject = [[NSUserDefaults standardUserDefaults] getDefaultDictionaryForKey:@"prohibitedProcesses"];
    return newObject.mutableCopy;
}

- (void) addObject:(id)object {
    [super addObject:object];
    [self removeSelectedObjects:self.selectedObjects];
    [self setSelectedObjects:@[object]];
    [self.prefsApplicationViewController selectedProhibitedProccessChanged];
}

- (void) remove:(id)sender
{
    if (!defaultProhibitedProcesses) {
        NSDictionary *defaultSEBSettings = [[NSUserDefaults standardUserDefaults] sebDefaultSettings];
        defaultProhibitedProcesses = defaultSEBSettings[@"org_safeexambrowser_SEB_prohibitedProcesses"];
    }
    
    NSArray *selectedObjects = [self selectedObjects];
    NSUInteger i = 0;
    while (i < selectedObjects.count) {
        NSDictionary *selectedProcess = selectedObjects[i];
        NSString *bundleID = selectedProcess[@"identifier"];
        if (bundleID.length > 0) {
            NSDictionary *matchingDefaultProcess = [self defaultProhibitedProcessWithKey:@"identifier" andValue:bundleID];
            if (matchingDefaultProcess && [matchingDefaultProcess[@"os"] longValue] == [selectedProcess[@"os"] longValue]) {
                if ([selectedProcess[@"active"] boolValue] == YES) {
                    [selectedProcess setValue:@NO forKey:@"active"];
                } else {
                    [self showAlertCannotRemoveProcess];
                }
                return;
            }
        }
        NSDictionary *matchingDefaultProcess = [self defaultProhibitedProcessWithKey:@"executable" andValue:selectedProcess[@"executable"]];
        if (matchingDefaultProcess && [matchingDefaultProcess[@"os"] longValue] == [selectedProcess[@"os"] longValue]) {
            if ([selectedProcess[@"active"] boolValue] == YES) {
                [selectedProcess setValue:@NO forKey:@"active"];
            } else {
                [self showAlertCannotRemoveProcess];
            }
        } else {
            NSUInteger selectedObjectIndex = [self selectionIndex];
            [super remove:sender];
            if (selectedObjectIndex != 0) {
                [self setSelectionIndex:selectedObjectIndex-1];
            }
        }
        i ++;
    }
}

- (void) showAlertCannotRemoveProcess
{
    [self.prefsApplicationViewController showAlertCannotRemoveProcess];
}


- (NSDictionary *) defaultProhibitedProcessWithKey:(NSString *)key andValue:(NSString *)value
{
    NSString *predicateFormatString = [NSString stringWithFormat:@"%@ ==[cd] \%%@", key];
    NSPredicate *processFilter = [NSPredicate predicateWithFormat:predicateFormatString, value];
    NSArray *foundProcesses = [defaultProhibitedProcesses filteredArrayUsingPredicate:processFilter];
    if (foundProcesses.count > 0) {
        return foundProcesses[0];
    } else {
        return nil;
    }
}


@end
