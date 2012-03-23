//
//  MameFileManagerTest.h
//  mameosx
//
//  Created by Dave Dribin on 9/16/06.
//

#import <SenTestingKit/SenTestingKit.h>


@class MameFileManager;

@interface MameFileManagerTest : SenTestCase
{
    MameFileManager * mFileManager;
    NSString * mResourcePath;
}

@end
