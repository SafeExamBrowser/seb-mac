//
//  ExamStartPage.m
//  Safe Exam Browser
//

#import "ExamStartPage.h"

static NSString *const ExamLandingPageName = @"ExamStart";
static NSString *const ExamLinkScheme = @"exambrowser";

@implementation ExamStartPage

+ (NSURL *)landingPageURL
{
    return [[NSBundle mainBundle] URLForResource:ExamLandingPageName withExtension:@"html"];
}


+ (BOOL)isLandingPageURL:(NSURL *)url
{
    NSURL *landingPageURL = [self landingPageURL];
    return url.isFileURL && landingPageURL &&
    [url.URLByStandardizingPath.path isEqualToString:landingPageURL.URLByStandardizingPath.path];
}


+ (NSURL *)examURLFromLink:(NSString *)link
{
    NSString *text = [link stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) {
        return nil;
    }

    // exambrowser://open?url=<link>  or  exambrowser://<link>
    NSString *schemePrefix = [ExamLinkScheme stringByAppendingString:@":"];
    if ([text.lowercaseString hasPrefix:schemePrefix]) {
        NSString *rest = [text substringFromIndex:schemePrefix.length];
        while ([rest hasPrefix:@"/"]) {
            rest = [rest substringFromIndex:1];
        }
        NSString *embedded = nil;
        if ([rest.lowercaseString hasPrefix:@"open?"]) {
            NSURLComponents *components = [NSURLComponents componentsWithString:[@"x://x/?" stringByAppendingString:[rest substringFromIndex:5]]];
            for (NSURLQueryItem *item in components.queryItems) {
                if ([item.name isEqualToString:@"url"]) {
                    embedded = item.value;
                }
            }
        } else {
            embedded = rest.stringByRemovingPercentEncoding ?: rest;
            if ([rest rangeOfString:@"://"].location != NSNotFound) {
                embedded = rest;
            }
        }
        text = [embedded stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0) {
            return nil;
        }
    }

    // No scheme: "exam.example.edu/quiz" means https://exam.example.edu/quiz
    if ([text rangeOfString:@"://"].location == NSNotFound) {
        if ([text hasPrefix:@"//"]) {
            text = [@"https:" stringByAppendingString:text];
        } else if ([text rangeOfString:@" "].location != NSNotFound || [self looksLikeOtherScheme:text]) {
            return nil;
        } else if ([text rangeOfString:@"."].location == NSNotFound && ![self isSingleLabelAddress:text]) {
            return nil;
        } else {
            text = [@"https://" stringByAppendingString:text];
        }
    }

    NSURL *url = [NSURL URLWithString:text];
    if (!url) {
        // Characters a browser would accept but NSURL doesn't, such as spaces or non-ASCII letters
        NSMutableCharacterSet *allowed = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
        [allowed formUnionWithCharacterSet:[NSCharacterSet URLPathAllowedCharacterSet]];
        [allowed addCharactersInString:@"#%"];
        url = [NSURL URLWithString:[text stringByAddingPercentEncodingWithAllowedCharacters:allowed]];
    }
    NSString *scheme = url.scheme.lowercaseString;
    BOOL usableScheme = [@[@"https", @"http", @"seb", @"sebs"] containsObject:scheme];
    if (!url || !usableScheme || url.host.length == 0) {
        return nil;
    }
    return url;
}


// "mailto:x", "tel:123", "javascript:...", "data:...", "about:blank": text that starts like a URL scheme, which
// is not followed by a port number (that would be "host:8080")
+ (BOOL)looksLikeOtherScheme:(NSString *)text
{
    NSRegularExpression *shape = [NSRegularExpression regularExpressionWithPattern:@"^[A-Za-z][A-Za-z0-9+.-]*:(?![0-9])" options:0 error:nil];
    return [shape numberOfMatchesInString:text options:0 range:NSMakeRange(0, text.length)] == 1;
}


// An address without a dot is only accepted in the shape of an intranet host: "moodle", "moodle/quiz",
// "moodle:8080/x". Anything with other punctuation ("javascript:alert(1)", "data:text/html,...") is not.
+ (BOOL)isSingleLabelAddress:(NSString *)text
{
    NSRegularExpression *shape = [NSRegularExpression regularExpressionWithPattern:@"^[A-Za-z0-9][A-Za-z0-9-]*(:[0-9]{1,5})?(/[^\\s]*)?$" options:0 error:nil];
    return [shape numberOfMatchesInString:text options:0 range:NSMakeRange(0, text.length)] == 1;
}


+ (BOOL)isConfigURL:(NSURL *)url
{
    NSString *scheme = url.scheme.lowercaseString;
    return [scheme isEqualToString:@"seb"] || [scheme isEqualToString:@"sebs"] ||
    [url.pathExtension caseInsensitiveCompare:@"seb"] == NSOrderedSame;
}

@end
