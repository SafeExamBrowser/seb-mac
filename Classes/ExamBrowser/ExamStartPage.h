//
//  ExamStartPage.h
//  Safe Exam Browser
//
//  The page shown when no exam is opened yet, and the parsing of whatever link
//  a student pastes there or opens from outside (any URL, seb:// link or .seb URL).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExamStartPage : NSObject

/// The bundled page with the field for an exam link
+ (nullable NSURL *)landingPageURL;

+ (BOOL)isLandingPageURL:(nullable NSURL *)url;

/// Turns what a student typed, or what an exambrowser:// link carries, into a URL SEB can open:
/// https://, http://, seb:// or sebs:// (a scheme-less "exam.example.edu/quiz" gets https://).
/// Returns nil if it can't be an exam link.
+ (nullable NSURL *)examURLFromLink:(NSString *)link;

/// A seb(s):// link, or an http(s) link to a .seb file: SEB downloads it as a configuration
+ (BOOL)isConfigURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
