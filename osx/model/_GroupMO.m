// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GroupMO.m instead.

#import "_GroupMO.h"

@implementation _GroupMO



- (NSString*)name {
	[self willAccessValueForKey:@"name"];
	NSString *result = [self primitiveValueForKey:@"name"];
	[self didAccessValueForKey:@"name"];

	return result;
}

- (void)setName:(NSString*)value_ {
    [self willChangeValueForKey:@"name"];
    [self setPrimitiveValue:value_ forKey:@"name"];
    [self didChangeValueForKey:@"name"];
}






	
- (void)addMembers:(NSSet*)value_ {
	[self willChangeValueForKey:@"members" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
    [[self primitiveValueForKey:@"members"] unionSet:value_];
    [self didChangeValueForKey:@"members" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeMembers:(NSSet*)value_ {
	[self willChangeValueForKey:@"members" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"members"] minusSet:value_];
	[self didChangeValueForKey:@"members" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addMembersObject:(GameMO*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"members" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"members"] addObject:value_];
    [self didChangeValueForKey:@"members" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeMembersObject:(GameMO*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"members" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"members"] removeObject:value_];
	[self didChangeValueForKey:@"members" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)membersSet {
	return [self mutableSetValueForKey:@"members"];
}
	

@end
