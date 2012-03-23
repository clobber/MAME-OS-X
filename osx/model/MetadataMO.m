#import "MetadataMO.h"
#import "NSXReturnThrowError.h"
#import "JRLog.h"

static void JRLogAssertWarn(BOOL condition, NSString * format_, ...)
{
    if (!condition)
    {
        va_list args;
        va_start(args, format_);
        NSString *message = [[[NSString alloc] initWithFormat:format_ arguments:args] autorelease];
        va_end(args);
        JRCLogWarn(@"%@", message);
    }
}

@implementation MetadataMO

+ (NSString *) entityName;
{
    return @"Metadata";
}

+ (NSEntityDescription *) entityInContext: (NSManagedObjectContext *) context;
{
    return [NSEntityDescription entityForName: [self entityName]
                       inManagedObjectContext: context];
}

+ (NSArray *) allWithSortDesriptors: (NSArray *) sortDescriptors
                          inContext: (NSManagedObjectContext *) context;
{
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity: [self entityInContext: context]];
    
    if (sortDescriptors != nil)
    {
        [request setSortDescriptors: sortDescriptors];
    }
    
    NSError * error = nil;
    NSArray * results = [context executeFetchRequest: request error: &error];
    if (results == nil)
    {
        NSXRaiseError(error);
    }
    return results;
}

+ (id) createInContext: (NSManagedObjectContext *) context;
{
    [NSEntityDescription insertNewObjectForEntityForName: [self entityName]
                                  inManagedObjectContext: context];
}

+ (MetadataMO *) defaultMetadataInContext: (NSManagedObjectContext *) context;
{
    NSArray * allMetadata = [self allWithSortDesriptors: nil inContext: context];
    unsigned count = [allMetadata count];
    JRLogAssertWarn(count <= 1, @"count <= 1 expected");
    
    MetadataMO * metadata = nil;
    if ([allMetadata count] == 0)
        metadata = [self createInContext: context];
    else
        metadata = [allMetadata objectAtIndex: 0];
    
    return metadata;
}

@end
