// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GameMO.m instead.

#import "_GameMO.h"

@implementation _GameMO



- (NSDate*)auditDate {
	[self willAccessValueForKey:@"auditDate"];
	NSDate *result = [self primitiveValueForKey:@"auditDate"];
	[self didAccessValueForKey:@"auditDate"];

	return result;
}

- (void)setAuditDate:(NSDate*)value_ {
    [self willChangeValueForKey:@"auditDate"];
    [self setPrimitiveValue:value_ forKey:@"auditDate"];
    [self didChangeValueForKey:@"auditDate"];
}






- (NSString*)year {
	[self willAccessValueForKey:@"year"];
	NSString *result = [self primitiveValueForKey:@"year"];
	[self didAccessValueForKey:@"year"];

	return result;
}

- (void)setYear:(NSString*)value_ {
    [self willChangeValueForKey:@"year"];
    [self setPrimitiveValue:value_ forKey:@"year"];
    [self didChangeValueForKey:@"year"];
}






- (NSString*)auditVersion {
	[self willAccessValueForKey:@"auditVersion"];
	NSString *result = [self primitiveValueForKey:@"auditVersion"];
	[self didAccessValueForKey:@"auditVersion"];

	return result;
}

- (void)setAuditVersion:(NSString*)value_ {
    [self willChangeValueForKey:@"auditVersion"];
    [self setPrimitiveValue:value_ forKey:@"auditVersion"];
    [self didChangeValueForKey:@"auditVersion"];
}






- (NSNumber*)favorite {
	[self willAccessValueForKey:@"favorite"];
	NSNumber *result = [self primitiveValueForKey:@"favorite"];
	[self didAccessValueForKey:@"favorite"];

	return result;
}

- (void)setFavorite:(NSNumber*)value_ {
    [self willChangeValueForKey:@"favorite"];
    [self setPrimitiveValue:value_ forKey:@"favorite"];
    [self didChangeValueForKey:@"favorite"];
}



- (BOOL)favoriteValue {
	return [[self favorite] boolValue];
}

- (void)setFavoriteValue:(BOOL)value_ {
	[self setFavorite:[NSNumber numberWithBool:value_]];
}






- (NSNumber*)playCount {
	[self willAccessValueForKey:@"playCount"];
	NSNumber *result = [self primitiveValueForKey:@"playCount"];
	[self didAccessValueForKey:@"playCount"];

	return result;
}

- (void)setPlayCount:(NSNumber*)value_ {
    [self willChangeValueForKey:@"playCount"];
    [self setPrimitiveValue:value_ forKey:@"playCount"];
    [self didChangeValueForKey:@"playCount"];
}



- (int)playCountValue {
	return [[self playCount] intValue];
}

- (void)setPlayCountValue:(int)value_ {
	[self setPlayCount:[NSNumber numberWithInt:value_]];
}






- (NSDate*)lastPlayed {
	[self willAccessValueForKey:@"lastPlayed"];
	NSDate *result = [self primitiveValueForKey:@"lastPlayed"];
	[self didAccessValueForKey:@"lastPlayed"];

	return result;
}

- (void)setLastPlayed:(NSDate*)value_ {
    [self willChangeValueForKey:@"lastPlayed"];
    [self setPrimitiveValue:value_ forKey:@"lastPlayed"];
    [self didChangeValueForKey:@"lastPlayed"];
}






- (NSString*)manufacturer {
	[self willAccessValueForKey:@"manufacturer"];
	NSString *result = [self primitiveValueForKey:@"manufacturer"];
	[self didAccessValueForKey:@"manufacturer"];

	return result;
}

- (void)setManufacturer:(NSString*)value_ {
    [self willChangeValueForKey:@"manufacturer"];
    [self setPrimitiveValue:value_ forKey:@"manufacturer"];
    [self didChangeValueForKey:@"manufacturer"];
}






- (NSString*)parentShortName {
	[self willAccessValueForKey:@"parentShortName"];
	NSString *result = [self primitiveValueForKey:@"parentShortName"];
	[self didAccessValueForKey:@"parentShortName"];

	return result;
}

- (void)setParentShortName:(NSString*)value_ {
    [self willChangeValueForKey:@"parentShortName"];
    [self setPrimitiveValue:value_ forKey:@"parentShortName"];
    [self didChangeValueForKey:@"parentShortName"];
}






- (NSString*)shortName {
	[self willAccessValueForKey:@"shortName"];
	NSString *result = [self primitiveValueForKey:@"shortName"];
	[self didAccessValueForKey:@"shortName"];

	return result;
}

- (void)setShortName:(NSString*)value_ {
    [self willChangeValueForKey:@"shortName"];
    [self setPrimitiveValue:value_ forKey:@"shortName"];
    [self didChangeValueForKey:@"shortName"];
}






- (NSString*)longName {
	[self willAccessValueForKey:@"longName"];
	NSString *result = [self primitiveValueForKey:@"longName"];
	[self didAccessValueForKey:@"longName"];

	return result;
}

- (void)setLongName:(NSString*)value_ {
    [self willChangeValueForKey:@"longName"];
    [self setPrimitiveValue:value_ forKey:@"longName"];
    [self didChangeValueForKey:@"longName"];
}






- (NSNumber*)auditStatus {
	[self willAccessValueForKey:@"auditStatus"];
	NSNumber *result = [self primitiveValueForKey:@"auditStatus"];
	[self didAccessValueForKey:@"auditStatus"];

	return result;
}

- (void)setAuditStatus:(NSNumber*)value_ {
    [self willChangeValueForKey:@"auditStatus"];
    [self setPrimitiveValue:value_ forKey:@"auditStatus"];
    [self didChangeValueForKey:@"auditStatus"];
}



- (int)auditStatusValue {
	return [[self auditStatus] intValue];
}

- (void)setAuditStatusValue:(int)value_ {
	[self setAuditStatus:[NSNumber numberWithInt:value_]];
}






- (NSString*)auditNotes {
	[self willAccessValueForKey:@"auditNotes"];
	NSString *result = [self primitiveValueForKey:@"auditNotes"];
	[self didAccessValueForKey:@"auditNotes"];

	return result;
}

- (void)setAuditNotes:(NSString*)value_ {
    [self willChangeValueForKey:@"auditNotes"];
    [self setPrimitiveValue:value_ forKey:@"auditNotes"];
    [self didChangeValueForKey:@"auditNotes"];
}






	

- (GameMO*)parent {
	[self willAccessValueForKey:@"parent"];
	GameMO *result = [self primitiveValueForKey:@"parent"];
	[self didAccessValueForKey:@"parent"];
	return result;
}

- (void)setParent:(GameMO*)value_ {
	[self willChangeValueForKey:@"parent"];
	[self setPrimitiveValue:value_ forKey:@"parent"];
	[self didChangeValueForKey:@"parent"];
}

	

	
- (void)addGroups:(NSSet*)value_ {
	[self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
    [[self primitiveValueForKey:@"groups"] unionSet:value_];
    [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeGroups:(NSSet*)value_ {
	[self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"groups"] minusSet:value_];
	[self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addGroupsObject:(GroupMO*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"groups"] addObject:value_];
    [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeGroupsObject:(GroupMO*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"groups"] removeObject:value_];
	[self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)groupsSet {
	return [self mutableSetValueForKey:@"groups"];
}
	

	
- (void)addClones:(NSSet*)value_ {
	[self willChangeValueForKey:@"clones" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
    [[self primitiveValueForKey:@"clones"] unionSet:value_];
    [self didChangeValueForKey:@"clones" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeClones:(NSSet*)value_ {
	[self willChangeValueForKey:@"clones" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"clones"] minusSet:value_];
	[self didChangeValueForKey:@"clones" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addClonesObject:(GameMO*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"clones" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"clones"] addObject:value_];
    [self didChangeValueForKey:@"clones" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeClonesObject:(GameMO*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"clones" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"clones"] removeObject:value_];
	[self didChangeValueForKey:@"clones" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)clonesSet {
	return [self mutableSetValueForKey:@"clones"];
}
	

@end
