// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GameMO.h instead.

#import <CoreData/CoreData.h>



@class GameMO;

@class GroupMO;

@class GameMO;


@interface _GameMO : NSManagedObject {}


- (NSDate*)auditDate;
- (void)setAuditDate:(NSDate*)value_;

//- (BOOL)validateAuditDate:(id*)value_ error:(NSError**)error_;



- (NSString*)year;
- (void)setYear:(NSString*)value_;

//- (BOOL)validateYear:(id*)value_ error:(NSError**)error_;



- (NSString*)auditVersion;
- (void)setAuditVersion:(NSString*)value_;

//- (BOOL)validateAuditVersion:(id*)value_ error:(NSError**)error_;



- (NSNumber*)favorite;
- (void)setFavorite:(NSNumber*)value_;

- (BOOL)favoriteValue;
- (void)setFavoriteValue:(BOOL)value_;

//- (BOOL)validateFavorite:(id*)value_ error:(NSError**)error_;



- (NSNumber*)playCount;
- (void)setPlayCount:(NSNumber*)value_;

- (int)playCountValue;
- (void)setPlayCountValue:(int)value_;

//- (BOOL)validatePlayCount:(id*)value_ error:(NSError**)error_;



- (NSDate*)lastPlayed;
- (void)setLastPlayed:(NSDate*)value_;

//- (BOOL)validateLastPlayed:(id*)value_ error:(NSError**)error_;



- (NSString*)manufacturer;
- (void)setManufacturer:(NSString*)value_;

//- (BOOL)validateManufacturer:(id*)value_ error:(NSError**)error_;



- (NSString*)parentShortName;
- (void)setParentShortName:(NSString*)value_;

//- (BOOL)validateParentShortName:(id*)value_ error:(NSError**)error_;



- (NSString*)shortName;
- (void)setShortName:(NSString*)value_;

//- (BOOL)validateShortName:(id*)value_ error:(NSError**)error_;



- (NSString*)longName;
- (void)setLongName:(NSString*)value_;

//- (BOOL)validateLongName:(id*)value_ error:(NSError**)error_;



- (NSNumber*)auditStatus;
- (void)setAuditStatus:(NSNumber*)value_;

- (int)auditStatusValue;
- (void)setAuditStatusValue:(int)value_;

//- (BOOL)validateAuditStatus:(id*)value_ error:(NSError**)error_;



- (NSString*)auditNotes;
- (void)setAuditNotes:(NSString*)value_;

//- (BOOL)validateAuditNotes:(id*)value_ error:(NSError**)error_;




- (GameMO*)parent;
- (void)setParent:(GameMO*)value_;
//- (BOOL)validateParent:(id*)value_ error:(NSError**)error_;



- (void)addGroups:(NSSet*)value_;
- (void)removeGroups:(NSSet*)value_;
- (void)addGroupsObject:(GroupMO*)value_;
- (void)removeGroupsObject:(GroupMO*)value_;
- (NSMutableSet*)groupsSet;



- (void)addClones:(NSSet*)value_;
- (void)removeClones:(NSSet*)value_;
- (void)addClonesObject:(GameMO*)value_;
- (void)removeClonesObject:(GameMO*)value_;
- (NSMutableSet*)clonesSet;


@end
