//
//  Webpages.h
//  TellTheWeb
//
//  Created by Daniel R. Schneider on 29/04/14.
//  Copyright (c) 2014 art technologies Schneider & Schneider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Webpages : NSManagedObject

@property (nonatomic, retain) NSData * cachedData;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * loadDate;
@property (nonatomic, retain) NSData * preview;
@property (nonatomic, retain) NSNumber * readingList;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * unread;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * viewDate;

@end
