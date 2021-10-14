//
//  ZMRouterCenter.h
//  ZCommonUI
//
//  Created by Francis Zhuo on 4/3/21.
//  Copyright © 2021 zoom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZCommonUI/ZMRouterMacroUtil.h>

NS_ASSUME_NONNULL_BEGIN
/*!
 export protocol for routerA
 @code
 xxx.h
 @protocol protocolA<NSObject>
 @end
 
 @protocol protocolAA<NSObject>
 @end
 
 @interface routerA
 @end
 
 xxx.m
 @routerable(routerA, protocolA, protocolAA)
 @implementation routerA
 @end
 @endcode
 */
#define routerable(className, protocolName...) routerable_(className, protocolName)

/*!
 export protocol for routerA
 @code
 xxx.h
 @protocol protocolA<NSObject>
 @end
 
 @interface routerA
 @end
 
 xxx.m
 @implementation routerA
 ZMExportProtocol(protocolA)
 @end
 @endcode
 */
#define ZMExportProtocol(protocol...) ZMExportProtocol_(protocol)


/*!
 get Instance methods
 @code
 id<protocolA> objectA = ZMObjectFor(Protocol);
 @endcode
 */
#define ZMObjectFor(Protocol) [ZMRouterCenter.shared objectForProtocol:Protocol]

/*!
 get singleton methods
 @code
 id<protocolA> objectA = ZMSharedFor(Protocol);
 @endcode
 */
#define ZMSharedFor(Protocol) [ZMRouterCenter.shared singletonForProtocol:Protocol]

/*!
 observe xxx router did register
 @code
 [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(routerADidReady) name:ZMRouterReady object:@protocol(protocolA)];
 @endcode
 */
extern NSNotificationName const ZMRouterReady;

@interface ZMRouterCenter : NSObject
+ (instancetype)shared;

- (void)registerProtocol:(Protocol *)protocol forClass:(Class)aClass;
- (void)registerProtocols:(NSArray<Protocol *> *)protocols forClass:(Class)aClass;
- (nullable Class)classForProtocol:(Protocol *)protocol;
- (nullable id)objectForProtocol:(Protocol *)protocol;

- (void)registerSingleton:(id)Object forProtocol:(Protocol *)protocol;
- (void)removeSingletonForProtocol:(Protocol *)protocol;
- (nullable id)singletonForProtocol:(Protocol *)protocol;

- (void)registerSuccessAction:(void(^_Nullable)(void))action forProtocol:(Protocol *)protocol;
@end

NS_ASSUME_NONNULL_END

