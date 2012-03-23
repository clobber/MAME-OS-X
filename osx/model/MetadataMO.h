#import "_MetadataMO.h"

@interface MetadataMO : _MetadataMO {}

+ (NSString *) entityName;

+ (NSEntityDescription *) entityInContext: (NSManagedObjectContext *) context;

+ (NSArray *) allWithSortDesriptors: (NSArray *) sortDescriptors
                          inContext: (NSManagedObjectContext *) context;

+ (id) createInContext: (NSManagedObjectContext *) context;

+ (MetadataMO *) defaultMetadataInContext: (NSManagedObjectContext *) context;

@end
