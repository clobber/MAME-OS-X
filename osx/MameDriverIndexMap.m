//
//  MameDriverIndexMap.m
//  mameosx
//
//  Created by Dave Dribin on 12/4/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MameDriverIndexMap.h"


@implementation MameDriverIndexMap

static MameDriverIndexMap * sDefaultIndexMap = nil;

+ (MameDriverIndexMap *) defaultIndexMap;
{
    if (sDefaultIndexMap == nil)
    {
        //sDefaultIndexMap = [[self alloc] initWithDriverList: drivers];

    }
    return sDefaultIndexMap;
}

+ (unsigned) indexForShortName: (NSString *) shortName;
{
    return [[self defaultIndexMap] indexForShortName: shortName];
}

+ (NSArray *) allShortNames;
{
    return [[self defaultIndexMap] allShortNames];
}

- (id) initWithDriverList: (const driver_enumerator * const *) driverList;
{
    self = [super init];
    if (self == nil)
        return nil;

    mIndexByShortName = [[NSMutableDictionary alloc] init];

    /* iterate over drivers */
    int driverIndex;
    //for (driverIndex = 0; drivers[driverIndex]; driverIndex++)
    for (driverIndex = 0; driverIndex < driver_enumerator::total(); driverIndex++)
    //for (driverIndex = 0; &driver_enumerator::driver(driverIndex); driverIndex++)
    //for (driverIndex = 0; &driver_enumerator::driver(driverIndex); driverIndex++)
    {
        //const game_driver * driver = drivers[driverIndex];
        const game_driver * driver = &driver_list::driver(driverIndex);
        NSString * shortName = [NSString stringWithUTF8String: driver->name];
        [mIndexByShortName setObject: [NSNumber numberWithUnsignedInt: driverIndex]
                              forKey: shortName];
        
    }
    
    return self;
}

- (unsigned) indexForShortName: (NSString *) shortName;
{
    NSNumber * indexNumber = [mIndexByShortName valueForKey: shortName];
    if (indexNumber != nil)
        return [indexNumber unsignedIntValue];
    else
        return NSNotFound;
}

- (NSArray *) allShortNames;
{
    return [mIndexByShortName allKeys];
}

@end
