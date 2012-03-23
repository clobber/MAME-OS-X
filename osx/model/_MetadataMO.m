// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MetadataMO.m instead.

#import "_MetadataMO.h"

@implementation _MetadataMO



- (NSString*)lastUpdateVersion {
	[self willAccessValueForKey:@"lastUpdateVersion"];
	NSString *result = [self primitiveValueForKey:@"lastUpdateVersion"];
	[self didAccessValueForKey:@"lastUpdateVersion"];

	return result;
}

- (void)setLastUpdateVersion:(NSString*)value_ {
    [self willChangeValueForKey:@"lastUpdateVersion"];
    [self setPrimitiveValue:value_ forKey:@"lastUpdateVersion"];
    [self didChangeValueForKey:@"lastUpdateVersion"];
}






- (NSNumber*)lastUpdateCount {
	[self willAccessValueForKey:@"lastUpdateCount"];
	NSNumber *result = [self primitiveValueForKey:@"lastUpdateCount"];
	[self didAccessValueForKey:@"lastUpdateCount"];

	return result;
}

- (void)setLastUpdateCount:(NSNumber*)value_ {
    [self willChangeValueForKey:@"lastUpdateCount"];
    [self setPrimitiveValue:value_ forKey:@"lastUpdateCount"];
    [self didChangeValueForKey:@"lastUpdateCount"];
}



- (int)lastUpdateCountValue {
	return [[self lastUpdateCount] intValue];
}

- (void)setLastUpdateCountValue:(int)value_ {
	[self setLastUpdateCount:[NSNumber numberWithInt:value_]];
}






@end
