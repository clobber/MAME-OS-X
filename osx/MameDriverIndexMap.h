//
//  MameDriverIndexMap.h
//  mameosx
//
//  Created by Dave Dribin on 12/4/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "driver.h"

@interface MameDriverIndexMap : NSObject
{
    NSMutableDictionary * mIndexByShortName;
}

+ (MameDriverIndexMap *) defaultIndexMap;

+ (unsigned) indexForShortName: (NSString *) shortName;

+ (NSArray *) allShortNames;

- (id) initWithDriverList: (const game_driver * const *) driverList;

- (unsigned) indexForShortName: (NSString *) shortName;

- (NSArray *) allShortNames;

@end
