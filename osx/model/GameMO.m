#import "GameMO.h"
#import "GroupMO.h"
#import "RomAuditSummary.h"
#import "MameConfiguration.h"
#import "MameVersion.h"
#import "MameDriverIndexMap.h"
#import "NSXReturnThrowError.h"
#import "JRLog.h"
#import "audit.h"

@implementation GameMO

+ (void)initialize
{
    if (self == [GameMO class])
    {
#if 0
        NSArray *keys = [NSArray arrayWithObjects: @"groups", nil];
        [self setKeys: keys triggerChangeNotificationsForDependentKey: @"favoriteIcon"];
        [self setKeys: keys triggerChangeNotificationsForDependentKey: @"favorite"];
#endif
    }
}

+ (NSString *) entityName;
{
    return @"Game";
}

+ (NSEntityDescription *) entityInContext: (NSManagedObjectContext *) context;
{
    return [NSEntityDescription entityForName: [self entityName]
                       inManagedObjectContext: context];
}

+ (NSArray *) executeFetchRequest: (NSFetchRequest *) request
                  sortDescriptors: (NSArray *) sortDescriptors
                        inContext: (NSManagedObjectContext *) context;
{
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

+ (NSArray *) allWithSortDesriptors: (NSArray *) sortDescriptors
                          inContext: (NSManagedObjectContext *) context;
{
    NSFetchRequest * request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity: [self entityInContext: context]];
    return [self executeFetchRequest: request
                     sortDescriptors: sortDescriptors
                           inContext: context];
}

+ (id) createInContext: (NSManagedObjectContext *) context;
{
    return [NSEntityDescription insertNewObjectForEntityForName: [self entityName]
                                  inManagedObjectContext: context];
}

+ (GameMO *) findWithShortName: (NSString *) shortName
                     inContext: (NSManagedObjectContext *) context;
{
    NSManagedObjectModel * model = [[context persistentStoreCoordinator] managedObjectModel];
    NSDictionary * variables = [NSDictionary dictionaryWithObject: shortName
                                                           forKey: @"SHORT_NAME"];
    NSFetchRequest * request =
        [model fetchRequestFromTemplateWithName: @"gameWithShortName"
                          substitutionVariables: variables];
    
    NSError * error = nil;
    NSArray * results = [context executeFetchRequest: request error: &error];
    if (results == nil)
    {
        NSXRaiseError(error);
    }
    
    NSAssert([results count] <= 1, @"No more than one result");
    if ([results count] == 0)
        return nil;
    else
        return [results objectAtIndex: 0];
}

+ (GameMO *) findOrCreateWithShortName: (NSString *) shortName
                             inContext: (NSManagedObjectContext *) context;
{
    GameMO * game = [self findWithShortName: shortName inContext: context];
    if (game == nil)
    {
        game = [self createInContext: context];
        [game setShortName: shortName];
    }
    return game;
}

+ (NSArray *) gamesWithShortNames: (NSArray *) shortNames
                        inContext: (NSManagedObjectContext *) context;
{
    return [self gamesWithShortNames: shortNames
                     sortDescriptors: nil inContext: context];
}

+ (NSArray *) gamesWithShortNames: (NSArray *) shortNames
                  sortDescriptors: (NSArray *) sortDescriptors
                        inContext: (NSManagedObjectContext *) context;
{
    NSManagedObjectModel * model = [[context persistentStoreCoordinator] managedObjectModel];
    NSDictionary * variables = [NSDictionary dictionaryWithObject: shortNames
                                                           forKey: @"SHORT_NAMES"];
    NSFetchRequest * request =
        [model fetchRequestFromTemplateWithName: @"gamesWithShortNames"
                          substitutionVariables: variables];
    return [self executeFetchRequest: request
                     sortDescriptors: sortDescriptors
                           inContext: context];
}

+ (NSArray *) sortByShortName;
{
    return [NSArray arrayWithObject:
            [[[NSSortDescriptor alloc] initWithKey: @"shortName"
                                         ascending: YES] autorelease]];
}

+ (NSArray *) sortByLongName;
{
    NSSortDescriptor * descriptor =
        [[NSSortDescriptor alloc] initWithKey: @"longName"
                                    ascending: YES
                                     selector: @selector(caseInsensitiveCompare:)];
    return [NSArray arrayWithObject: [descriptor autorelease]];
}

- (void) toggleGroupMembership: (GroupMO *) group;
{
#if 0
    NSMutableSet * groups = [self groupsSet];
    if ([groups containsObject: group])
        [groups removeObject: group];
    else
        [groups addObject: group];
#else
    NSMutableSet * members = [group membersSet];
    if ([members containsObject: self])
        [members removeObject: self];
    else
        [members addObject: self];
#endif
}

extern GroupMO * mFavoritesGroup;

- (BOOL) isFavorite;
{
    return [self favoriteValue];
}

- (NSImage *) favoriteIcon;
{
    if ([self isFavorite])
        return [NSImage imageNamed: @"favorite-16"];
    else
        return nil;
}

- (void) toggleFavorite;
{
    [self setFavoriteValue: ![self favoriteValue]];
}

- (NSString *) displayName;
{
    return [NSString stringWithFormat:
        @"%@: %@, %@", [self shortName], [self manufacturer], [self year]];
}

- (NSString *) auditStatusString;
{
    NSNumber * auditStatus = [self auditStatus];
    if (auditStatus == nil)
        return @"Never Audited";
    
    switch ([auditStatus intValue])
    {
        case media_auditor::INCORRECT:
            return @"Bad";
            
        case media_auditor::CORRECT:
            return @"Good";
            
        case media_auditor::BEST_AVAILABLE:
            return @"Best Available";
            
        case media_auditor::NOTFOUND:
            return @"Not Found";
            
        default:
            return @"N/A";
    }
}

- (BOOL) audit;
{
    unsigned driverIndex = [MameDriverIndexMap indexForShortName: [self shortName]];
    if (driverIndex == NSNotFound)
        return NO;
    
    JRLogDebug(@"Auditing %@ (%@)", [self shortName], [self longName]);
    audit_record * auditRecords;
    //int recordCount;
    int res;
    
    // audit the ROMs in this set
    //media_auditor::summary recordCount = auditor.audit_media(AUDIT_VALIDATE_FAST);
    
    /* audit the ROMs in this set */
    //running_machine * machine;
    //driver_enumerator enumerator(machine->options());
    driver_enumerator enumerator(*[[MameConfiguration defaultConfiguration] coreOptions]);
    //enumerator.next();
    media_auditor auditor(enumerator);
    enumerator.set_current(driverIndex);
    int summary_status = auditor.audit_media(AUDIT_VALIDATE_FAST);

    
        RomAuditSummary * summary =
            [[RomAuditSummary alloc] initWithGameIndex: driverIndex
                                               summary: summary_status
                                           records: auditor.first()];
    free(auditRecords);
    [summary autorelease];
    [self setAuditStatusValue: [summary status]];
    [self setAuditNotes: [summary notes]];
    [self setAuditDate: [NSDate date]];
    [self setAuditVersion: [MameVersion marketingVersion]];
    return YES;
}

- (void) resetAuditStatus;
{
    [self setAuditDate: nil];
    [self setAuditNotes: nil];
    [self setAuditStatus: nil];
}

@end
