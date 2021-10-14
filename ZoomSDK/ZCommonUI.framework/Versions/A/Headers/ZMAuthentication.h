
//  ZMAuthentication.h


#import <Cocoa/Cocoa.h>
#import <Security/Authorization.h>

typedef NS_ENUM(NSUInteger, ZMRunAppleScriptResult)
{
    ZMRunAppleScriptResultSuccess,
    ZMRunAppleScriptResultCancel,
    ZMRunAppleScriptResultError
};

@interface ZMAuthentication : NSObject
{
    AuthorizationRef _authorizationRef;
    id _delegate;
}

+ sharedInstance;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (OSStatus)zm_isAuthenticated:(NSString *)forCommand;
- (OSStatus)zm_authenticate:(NSString *)forCommand;
- (void)zm_deauthenticate;

- (int)zm_getPID:(NSString *)forProcess;
- (int)zm_processRunningTime:(NSString *)forProcess;

- (OSStatus)zm_executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments;
- (OSStatus)zm_executeCommandSynced:(NSString *)pathToCommand withArgs:(NSArray *)arguments;

- (BOOL)killProcess:(NSString *)commandFromPS withSignal:(int)signal;
- (BOOL)authRemovePath:(NSString*)rmPath;
- (BOOL)authCopyPath:(NSString*)srcPath toPath:(NSString*)destPath;

/*
 when Macos >= 10.15, use the way of AppleScript to Authenticate Permission,
 which can avoid crash by using AuthorizationExecuteWithPrivileges in Masos 10.15.
 */
- (ZMRunAppleScriptResult)runAppleScript:(NSString *)script errorDescription:(NSString **)errorDescription;


/// Run apple script helper method
/// @param handlerName  the name of the function need to be called
/// @param script apple script body
/// @param parameterList parameter list
/// @param errorInfo  error information
/// @discussion when your apple script have any parameter use this methold
- (NSAppleEventDescriptor *)runAppleScriptName:(NSString *)handlerName
                                        script:(NSString *)script
                         withArrayOfParameters:(NSAppleEventDescriptor*) parameterList
                                     errorInfo:(NSDictionary **) errorInfo;

@end

@interface NSObject (ZMAuthenticationDelegate)

- (void)zm_authenticationDidFinish:(int)resultCode;

- (void)zm_authenticationFail:(int)resultCode;

- (void)zm_authenticationDidDeauthorize:(ZMAuthentication *)authentication;

- (NSString*)zm_authenticationGetPromptText;
@end
