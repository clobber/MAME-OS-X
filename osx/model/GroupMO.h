#import "_GroupMO.h"

@interface GroupMO : _GroupMO {}

+ (GroupMO *) createInContext: (NSManagedObjectContext *) context;

+ (GroupMO *) findWithName: (NSString *) name
                 inContext: (NSManagedObjectContext *) context;

+ (GroupMO *) findOrCreateGroupWithName: (NSString *) name
                              inContext: (NSManagedObjectContext *) context;

@end

extern NSString * GroupFavorites;