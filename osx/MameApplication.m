//
//  MameApplication.m
//  mameosx
//
//  Created by Dave Dribin on 1/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MameApplication.h"
#import "MamePreferences.h"
#import "MameFileLogger.h"

@implementation MameApplication

+ initialize;
{
    // Since NIB class load order is nondeterministic, the only way to 
    // guarantee that preferences are setup before any class in the NIB
    // is loaded is to subclass NSApplication.  This is loaded and
    // initialized before the main NIB is even loaded.
    [[MamePreferences standardPreferences] registerDefaults];
    [NSObject setJRLogLogger: [MameFileLogger defaultLogger]];
}

- (void) run;
{
    [super run];
    [[MameFileLogger defaultLogger] flushLogFile];
}

@end
