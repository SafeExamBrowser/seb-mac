//
//  ZMUtil.h
//  ZCommonUI
//
//  Created by John on 10/26/16.
//  Copyright (c) 2016 zoom. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SCHEMA_HTTP  (@"http")
#define SCHEMA_HTTPS (@"https")
#define SCHEMA_MAILTO   (@"mailto")

#define RGB(r,g,b)      [NSColor colorWithCalibratedRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]
#define RGBA(r,g,b,a)   [NSColor colorWithCalibratedRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define SRGB(r,g,b)     [NSColor colorWithSRGBRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]
#define SRGBA(r,g,b,a)  [NSColor colorWithSRGBRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define DRGB(r,g,b)     [NSColor colorWithDeviceRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]
#define DRGBA(r,g,b,a)  [NSColor colorWithDeviceRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

#ifndef IsEmptyString
#define IsEmptyString(str) ([ZMUtil isEmptyString:str])
#endif

#ifndef IsFloatEqualToZero
#define IsFloatEqualToZero(num) (fabs(num) < 0.0000001)
#endif

#ifndef IsFloatEqualOrLessThanZero
#define IsFloatEqualOrLessThanZero(num) ((num) < 0.0000001)
#endif

#ifndef ZM_GET_NSERROR
#define ZM_GET_NSERROR(domain,errorcode,desc) [NSError errorWithDomain:domain code:errorcode userInfo:@{NSLocalizedDescriptionKey:(desc)?(desc):@""}]
#endif

#define Release_View(x) { if(nil != x) \
                        {\
                            if(nil != x.superview) \
                                [x removeFromSuperview]; \
                            [x release];              \
                            x = nil;                  \
                        }}

#define Release_Button(x) { if(nil != x) \
                        {\
                            if(nil != x.superview) \
                                [x removeFromSuperview]; \
                            x.action = nil; x.target = nil; \
                            [x release];              \
                            x = nil;                  \
                        }}

#define Release_View_With_CleanUp(x) { if(nil != x) \
                                    {\
                                        if(nil != x.superview) \
                                            [x removeFromSuperview]; \
                                        [x cleanUp]; \
                                        [x release];              \
                                        x = nil;                  \
                                    }}


extern NSString* kPhoneNumber;
extern NSString* kMeetingNumber;

typedef enum
{
    ID_Unknow_Language = 0,
    ID_English_Language,
    ID_Chinese_Simplified_Language,
    ID_Chinese_Traditional_Language,
    ID_Italian_Language,
    ID_French_Language,
    ID_German_Language,
    ID_Spanish_Language,
    ID_Japanese_Language,
    ID_Portuguese_Language,
    ID_Russian_Language,
    ID_Korean_Languate,
    ID_Vietnamese_Languate,
} ID_CLIENT_LANGUAGE;

@interface ZMUtil : NSObject

//change key event to mouse event, change menu location
+ (NSEvent*)zmEventWithEvent:(NSEvent*)inOldEvent newLocation:(NSPoint)inNewLocation;
+ (ID_CLIENT_LANGUAGE)getCurrentLaguageIdentifer;
+ (NSString*)getCurrentLaguageCode;

//get view rect at screen coordinates
+ (NSRect)getScreenCoordinatesRectForView:(NSView*)inView;

//get popup window location in middle of screen or another window
+ (NSPoint)calcWindowPoint:(NSWindow*)window baseWindow:(NSWindow*)baseWindow baseScreen:(NSScreen*)screen;

//check if email is valid
+ (BOOL)isValidEmail:(NSString*)inEmail;

+ (BOOL)isEmptyString:(NSString *)string;

/**
 check if Contain Email
 */
+ (BOOL)isContainEmail:(NSString*)inEmail;

//string width/height
+(CGFloat)heightForWidth:(CGFloat)inWidth attributeString:(NSAttributedString*)inAttString;
+(CGFloat)widthForHeight:(CGFloat)inHeight attributeString:(NSAttributedString*)inAttString;
+ (NSString*)clipString:(NSString*)string limitHeight:(CGFloat)limitHeight limitWidth:(CGFloat)limitWidth attribute:(NSDictionary*)attr isMyNote:(BOOL)isMyNote;
+ (NSMutableArray*)parseHTTPURLs:(NSString*)body;
+ (NSArray*)parseURLs:(NSMutableAttributedString*)inMsg;
+ (NSArray*)parseURLs:(NSMutableAttributedString*)inMsg forCommonApp:(BOOL)isCommonApp;
+ (NSArray*)parseURLs:(NSMutableAttributedString*)inMsg urlOnly:(BOOL)urlOnly;

+ (void)parseEmails:(NSMutableAttributedString*)textContent;
#pragma mark - window level
+ (NSInteger)getNormalWindowLevel;//0
+ (NSInteger)getFloatingWindowLevel;//3
+ (NSInteger)getModalPanelWindowLevel;//8
+ (NSInteger)getPopUpWindowLevel;//97
+ (NSInteger)getPopUpMenuLevel;//99

+ (NSData*)getPicPreviewDateWithPath:(NSString*)filePath;
+ (NSString *)getFileIntegrationTypeString:(NSInteger)fileIntegrationType defaultRetString:(NSString*)ret;
+ (NSComparisonResult)compareVersionString:(NSString*)string1 with:(NSString*)string2;//ZOOM-68189
+ (BOOL)recreateSymbolicLinkForLib:(NSString*)libName inPath:(NSString*)path error:(NSError **)error;//ZOOM-68189
+ (NSSize)calculateAttributeString:(NSAttributedString *)string maxWidth:(CGFloat)maxWidth textContainer:(NSTextContainer *)textContainer isBotFieldMessage:(BOOL)isBotField;
+ (NSSize)calculateAttributeString:(NSAttributedString *)string maxWidth:(CGFloat)maxWidth textContainer:(NSTextContainer *)textContainer;
+ (NSSize)calculateAttributeString:(NSAttributedString *)string maxWidth:(CGFloat)maxWidth textContainer:(NSTextContainer *)textContainer isBotFieldMessage:(BOOL)isBotField font:(NSFont*)font;
+ (NSSize)calculateAttributeString:(NSAttributedString *)string maxWidth:(CGFloat)maxWidth textContainer:(NSTextContainer *)textContainer maxLine:(NSInteger)maxLine;

#pragma mark - draw elements
//ZOOM-72640 RTT
//draw arrow(type==0) or triangle(type==1);  up(direction=0),down(1),left(2),right(3)
+ (void)drawArrow:(NSRect)rect lineWidth:(float)width color:(NSColor*)color direction:(int)direction type:(int)type;
+ (void)drawTick:(NSRect)rect lineWidth:(float)width color:(NSColor*)color;
+ (void)drawCross:(NSRect)rect lineWidth:(float)width color:(NSColor*)color;

#pragma mark - pasteboard

+ (void)cleanPasteboard;
@end
