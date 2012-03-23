// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GroupMO.h instead.

#import <CoreData/CoreData.h>



@class GameMO;


@interface _GroupMO : NSManagedObject {}


- (NSString*)name;
- (void)setName:(NSString*)value_;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




- (void)addMembers:(NSSet*)value_;
- (void)removeMembers:(NSSet*)value_;
- (void)addMembersObject:(GameMO*)value_;
- (void)removeMembersObject:(GameMO*)value_;
- (NSMutableSet*)membersSet;


@end
