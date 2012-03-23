#import "GroupMO.h"
#import "NSXReturnThrowError.h"

NSString * GroupFavorites = @"Favorites";

@implementation GroupMO

+ (GroupMO *) createInContext: (NSManagedObjectContext *) context;
{
    return [NSEntityDescription insertNewObjectForEntityForName: @"Group"
                                         inManagedObjectContext: context];
}

+ (GroupMO *) findWithName: (NSString *) name
                 inContext: (NSManagedObjectContext *) context;
{
    NSManagedObjectModel * model =
        [[context persistentStoreCoordinator] managedObjectModel];
    NSDictionary * variables = [NSDictionary dictionaryWithObject: name
                                                           forKey: @"NAME"];
    NSFetchRequest * request =
        [model fetchRequestFromTemplateWithName: @"groupByName"
                          substitutionVariables: variables];
    
    NSError * error = nil;
    NSArray * results = [context executeFetchRequest: request error: &error];
    if (results == nil)
    {
        NSXRaiseError(error);
    }

    NSAssert([results count] <= 1, @"No more than one result");
    if ([results count] == 1)
        return [results objectAtIndex: 0];
    else
        return nil;
}

+ (GroupMO *) findOrCreateGroupWithName: (NSString *) name
                              inContext: (NSManagedObjectContext *) context;
{
    GroupMO * result = [self findWithName: name inContext: context];
    if (result == nil)
    {
        result = [GroupMO createInContext: context];
        [result setName: name];
    }

    return result;
}

@end
