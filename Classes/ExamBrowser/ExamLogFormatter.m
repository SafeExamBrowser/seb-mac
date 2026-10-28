//
//  ExamLogFormatter.m
//  Safe Exam Browser
//

#import "ExamLogFormatter.h"

// Lines are formatted on the logger's queue, some time after they were logged. So the phase a line belongs to is
// decided by when the line was logged (its timestamp) against when the phase changed, never by when it is formatted.
static NSMutableArray<NSArray *> *phaseChanges;    // @[ NSDate, @(phase) ], oldest first
static NSMutableArray<NSArray *> *muteIntervals;   // @[ start NSDate, end NSDate, @(phase it was set in) ]
static NSLock *phaseLock;

@implementation ExamLogFormatter

+ (void)initialize
{
    if (self == [ExamLogFormatter class]) {
        phaseLock = [NSLock new];
        muteIntervals = [NSMutableArray new];
        phaseChanges = [NSMutableArray arrayWithObject:@[[NSDate dateWithTimeIntervalSince1970:0], @(ExamLogPhaseStartup)]];
    }
}


+ (void)setPhase:(ExamLogPhase)phase
{
    [phaseLock lock];
    [phaseChanges addObject:@[[NSDate date], @(phase)]];
    [phaseLock unlock];
}


+ (ExamLogPhase)phase
{
    [phaseLock lock];
    ExamLogPhase phase = (ExamLogPhase)[phaseChanges.lastObject[1] integerValue];
    [phaseLock unlock];
    return phase;
}


// Everything logged from now until the given number of seconds later is dropped (except the
// list of running applications). Used around the exam lock: whatever toggling it sets off inside SEB is never logged.
+ (void)muteFor:(NSTimeInterval)seconds
{
    NSDate *now = [NSDate date];
    ExamLogPhase phase = [self phaseAtDate:now];
    [phaseLock lock];
    [muteIntervals addObject:@[now, [now dateByAddingTimeInterval:seconds], @(phase)]];
    [phaseLock unlock];
}


// Muted only within the phase it was set in: locking while the exam runs must never swallow the lines of the quit
+ (BOOL)isMutedAtDate:(NSDate *)date phase:(ExamLogPhase)phase
{
    BOOL muted = NO;
    [phaseLock lock];
    for (NSArray *interval in muteIntervals) {
        if ([interval[0] compare:date] != NSOrderedDescending && [interval[1] compare:date] == NSOrderedDescending
            && [interval[2] integerValue] == phase) {
            muted = YES;
            break;
        }
    }
    [phaseLock unlock];
    return muted;
}


// The phase that was current when a line was logged
+ (ExamLogPhase)phaseAtDate:(NSDate *)date
{
    ExamLogPhase phase = ExamLogPhaseStartup;
    [phaseLock lock];
    for (NSArray *change in phaseChanges) {
        if ([change[0] compare:date] == NSOrderedDescending) {
            break;
        }
        phase = (ExamLogPhase)[change[1] integerValue];
    }
    [phaseLock unlock];
    return phase;
}


// Lines that are never written, in any phase: they would show what the student does during the exam.
//   ://                         any web or file address (pages the student opens)
//   Title of current Page       the title of a page
//   clipboard / pasteboard      copying and pasting
//   download                    names of downloaded files
//   Started application, launched app, Activated app     applications the student starts or switches to
//   Switched back to SEB, Regain active, isActive property, App which switched Space     focus and window switching
// Everything else the original writes while SEB starts up and quits stays exactly as the original wrote it.
+ (NSRegularExpression *)neverLoggedPattern
{
    static NSRegularExpression *pattern;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pattern = [NSRegularExpression regularExpressionWithPattern:
                   @"://|Title of current Page|clipboard|pasteboard|download"
                   @"|Started application|launched app|Activated app|Switched back to SEB|Regain active|isActive property|App which switched Space"
                                                            options:NSRegularExpressionCaseInsensitive
                                                              error:nil];
    });
    return pattern;
}


// The two lists of the applications that were running when SEB started ("  Name (bundle ID: x)" and
// "Name, bundle ID: x"). They always stay: an application called "1Password" or "Wi-Fi Explorer" is still listed.
+ (NSRegularExpression *)runningApplicationLinePattern
{
    static NSRegularExpression *pattern;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pattern = [NSRegularExpression regularExpressionWithPattern:@"^(?: {2}[^\\n]+ \\(bundle ID: [^\\n]*\\)|[^:\\n]+, bundle ID: [^\\n]*)$"
                                                            options:0 error:nil];
    });
    return pattern;
}


// The original's marker lines ("---------- EXITING SEB - ENDING SESSION -------------"): the start and end of a session
// with their times. Nothing the lock sets off writes one.
+ (NSRegularExpression *)markerLinePattern
{
    static NSRegularExpression *pattern;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pattern = [NSRegularExpression regularExpressionWithPattern:@"^---------- [^\\n]+ -------------$" options:0 error:nil];
    });
    return pattern;
}


+ (BOOL)allowsMessage:(NSString *)message phase:(ExamLogPhase)phase muted:(BOOL)muted
{
#ifdef DEBUG
    // Debug builds only: the complete, unfiltered original log, for comparing against
    if (getenv("SEB_UNFILTERED_LOG") != NULL) {
        return YES;
    }
#endif
    if (phase == ExamLogPhaseRunning) {
        return NO;
    }
    if (message.length == 0) {
        return NO;
    }
    NSRange all = NSMakeRange(0, message.length);
    if ([[self runningApplicationLinePattern] numberOfMatchesInString:message options:0 range:all] > 0) {
        return YES;
    }
    BOOL marker = [[self markerLinePattern] numberOfMatchesInString:message options:0 range:all] > 0;
    if (muted && !marker) {
        return NO;
    }
    return [[self neverLoggedPattern] numberOfMatchesInString:message options:0 range:NSMakeRange(0, message.length)] == 0;
}


- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    ExamLogPhase phase = [ExamLogFormatter phaseAtDate:logMessage.timestamp];
    BOOL muted = [ExamLogFormatter isMutedAtDate:logMessage.timestamp phase:phase];
    if (![ExamLogFormatter allowsMessage:logMessage.message phase:phase muted:muted]) {
        return nil;
    }
    // The line itself is exactly what the original writes
    return [super formatLogMessage:logMessage];
}

@end
