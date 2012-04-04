//
//  AppDataModel.h
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const kVolunteerActivityType;

extern NSString * const kVolunteerActivity_NameField;
extern NSString * const kVolunteerActivity_DateTimeField;
extern NSString * const kVolunteerActivity_DurationField;
extern NSString * const kVolunteerParticipation_DurationField;


extern NSString * const kAppDataModel_ModelUpdatedNotice;


@interface AppDataModel : NSObject {
    NSDictionary *_Volunteer_Activity__c;
    NSMutableArray *_recentVolunteerActivities;
    NSMutableArray *_forthcomingVolunteerActivities;
    NSMutableArray *_myVolunteerActivities;

    NSDictionary *_myDonorRecord;
    
    NSMutableDictionary *_fullActivitiesById;
    NSMutableDictionary *_shallowActivitiesById;
    
    NSDateFormatter *_dateTimeStringFormatter;
}


@property (nonatomic, strong) NSDictionary *Volunteer_Activity__c;
@property (nonatomic, strong) NSDictionary *myDonorRecord;

@property (nonatomic, strong, readonly) NSArray   *recentVolunteerActivities;
@property (nonatomic, strong, readonly) NSArray   *myVolunteerActivities;
@property (nonatomic, strong, readonly) NSArray   *forthcomingVolunteerActivities;

@property (nonatomic, strong, readonly) NSMutableDictionary *fullActivitiesById;
@property (nonatomic, strong, readonly) NSMutableDictionary *shallowActivitiesById;

- (void)updateRecentVolunteerActivities:(NSArray*)recentActivities;
- (void)updateForthcomingVolunteerActivities:(NSArray*)recentActivities;
- (void)addMyParticpantRecords:(NSArray*)particpants;
- (void)addFullVolunteerActivity:(NSDictionary*)activity;

- (NSDate*)dateFromDateTimeString:(NSString*)dateTimeStr;
- (NSString*)dateTimeStringFromDate:(NSDate*)date;

@end
