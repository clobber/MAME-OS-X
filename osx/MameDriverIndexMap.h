//
//  MameDriverIndexMap.h
//  mameosx
//
//  Created by Dave Dribin on 12/4/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#include "driver.h"
#include "emu.h"

@interface MameDriverIndexMap : NSObject
{
    NSMutableDictionary * mIndexByShortName;
}

+ (MameDriverIndexMap *) defaultIndexMap;

+ (unsigned) indexForShortName: (NSString *) shortName;

+ (NSArray *) allShortNames;

- (id) initWithDriverList: (const driver_enumerator * const *) driverList;

- (unsigned) indexForShortName: (NSString *) shortName;

- (NSArray *) allShortNames;

@end
