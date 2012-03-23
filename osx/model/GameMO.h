#import "_GameMO.h"

@class GroupMO;

@interface GameMO : _GameMO
{
    /*
     * Don't make this a transient property, since updating it marks the
     * objects as dirty, which slows down saves.
     *
     * http://lists.apple.com/archives/cocoa-dev/2005/Aug/msg01080.html
     */
}

+ (NSString *) entityName;

+ (NSEntityDescription *) entityInContext: (NSManagedObjectContext *) context;

+ (NSArray *) executeFetchRequest: (NSFetchRequest *) request
                  sortDescriptors: (NSArray *) sortDescriptors
                        inContext: (NSManagedObjectContext *) context;

+ (NSArray *) allWithSortDesriptors: (NSArray *) sortDescriptors
                          inContext: (NSManagedObjectContext *) context;

+ (id) createInContext: (NSManagedObjectContext *) context;

+ (GameMO *) findWithShortName: (NSString *) shortName
                     inContext: (NSManagedObjectContext *) context;

+ (GameMO *) findOrCreateWithShortName: (NSString *) shortName
                             inContext: (NSManagedObjectContext *) context;

+ (NSArray *) gamesWithShortNames: (NSArray *) shortNames
                        inContext: (NSManagedObjectContext *) context;

+ (NSArray *) gamesWithShortNames: (NSArray *) shortNames
                  sortDescriptors: (NSArray *) sortDescriptors
                        inContext: (NSManagedObjectContext *) context;

+ (NSArray *) sortByShortName;

+ (NSArray *) sortByLongName;

- (void) toggleGroupMembership: (GroupMO *) group;

- (BOOL) isFavorite;
- (NSImage *) favoriteIcon;
- (void) toggleFavorite;

- (NSString *) displayName;
- (NSString *) auditStatusString;

- (BOOL) audit;

- (void) resetAuditStatus;

@end
