//
//  ZMRouterMacroUtil.h
//  ZCommonUI
//
//  Created by Francis Zhuo on 4/3/21.
//  Copyright © 2021 zoom. All rights reserved.
//

#import <ZCommonUI/ZMMacroUtil.h>

#define routerable_(className, ...) \
class className;\
@interface className(routerable)<ZMRoutableObject>\
@end\
@implementation className(routerable)\
ZMExportProtocol_(__VA_ARGS__)\
@end

#define ZMExportProtocol_(...) \
+ (void)load{ \
[ZMRouterCenter.shared registerProtocols:Protocols(__VA_ARGS__) forClass:self.class];\
}

#define Protocols(...)\
        @[metamacro_foreach_cxt(ProtocolItem,,, __VA_ARGS__)]

#define ProtocolItem(INDEX, CONTEXT, protocolName) \
        @protocol(protocolName),


#define BundleLoad_(bundleName) \
if(![NSBundle loadBundleWithComponentName:bundleName]){ \
    dispatch_async(dispatch_get_main_queue(), ^{ \
        [ZMRouterCenter.shared registerSuccessAction:^{ \
            id<ZMOndemandProtocol> download = ZMSharedFor(@protocol(ZMOndemandProtocol)); \
            [download downloadWithBundleName:bundleName progress:nil completion:^(BOOL success, NSError* error){ \
                [NSBundle loadBundleWithComponentName:bundleName]; \
            }]; \
        } forProtocol:@protocol(ZMOndemandProtocol)]; \
    }); \
}

