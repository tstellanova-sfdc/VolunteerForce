//
//  AppDataModel.m
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import "AppDataModel.h"


NSString * const kVolunteerActivityType = @"Volunteer_Activity__c";

NSString * const kVolunteerActivity_DateTimeField = @"Date_and_Time__c";
NSString * const kVolunteerActivity_DurationField = @"Duration_hours__c";

NSString * const kVolunteerActivity_NameField = @"Name";

NSString * const kAppDataModel_ModelUpdatedNotice = @"AppDataModel_ModelUpdated";


@interface AppDataModel (Private)

- (void)postDeferredUpdateNotification:(NSString*)subcategory;

@end

@implementation AppDataModel

@synthesize Volunteer_Activity__c = _Volunteer_Activity__c;
@synthesize recentVolunteerActivities = _recentVolunteerActivities;
@synthesize myVolunteerActivities = _myVolunteerActivities;
@synthesize fullActivitiesById = _fullActivitiesById;
@synthesize shallowActivitiesById = _shallowActivitiesById;

- (id)init {
    self = [super init];
    if (self) {
        _fullActivitiesById = [[NSMutableDictionary alloc] init];
        _shallowActivitiesById  = [[NSMutableDictionary alloc] init];

        _dateTimeStringFormatter = [[NSDateFormatter alloc] init];    
        //eg  2010-03-06T18:14:00.000+0000
        [_dateTimeStringFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSZ"];
    }
    
    return self;
}

- (void)dealloc {
    [_dateTimeStringFormatter release]; _dateTimeStringFormatter = nil;
    [_fullActivitiesById release]; _fullActivitiesById = nil;
    [_shallowActivitiesById release]; _shallowActivitiesById = nil;
}


- (void)addFullVolunteerActivity:(NSDictionary*)activity
{
    NSString *activityId = [activity objectForKey:@"Id"];
    [_fullActivitiesById setObject:activity forKey:activityId];
    [_shallowActivitiesById setObject:activity forKey:activityId];
    [_recentVolunteerActivities insertObject:activity atIndex:0];
    
    [self postDeferredUpdateNotification:nil];

}


- (void)updateRecentVolunteerActivities:(NSArray*)recentActivities 
{
    for (NSDictionary *activity in recentActivities) {
        NSString *activityId = [activity objectForKey:@"Id"];
        [self.shallowActivitiesById setObject:activity forKey:activityId];
    }
    
    [_recentVolunteerActivities release];
    _recentVolunteerActivities = [[NSMutableArray alloc] initWithArray:recentActivities];
    [self postDeferredUpdateNotification:nil];
}

- (void)addMyParticpantRecords:(NSArray*)particpants 
{
    [_myVolunteerActivities release]; _myVolunteerActivities = nil;
    
    NSMutableArray *myActivities = [[NSMutableArray alloc] initWithCapacity:[particpants count] ];
    
    for (NSDictionary *record in particpants) {
        NSDictionary *activity = [record objectForKey:@"Volunteer_Activity__r"];
        NSString *activityId = [activity objectForKey:@"Id"];
        [self.shallowActivitiesById setObject:activity forKey:activityId];
        [myActivities addObject:activity];
    }

    _myVolunteerActivities = [[NSMutableArray alloc] initWithArray:myActivities];
    [myActivities release];
    
    [self postDeferredUpdateNotification:nil];
}




- (NSDate*)dateFromDateTimeString:(NSString*)dateTimeStr
{
    NSDate *date = [_dateTimeStringFormatter dateFromString:dateTimeStr];
    return date;
}

- (NSString*)dateTimeStringFromDate:(NSDate*)date
{
    NSString *result = [_dateTimeStringFormatter stringFromDate:date];
    return result;
}



- (void)postDeferredUpdateNotification:(NSString *)category
{    
    NSNotification *notice = [NSNotification notificationWithName:kAppDataModel_ModelUpdatedNotice 
                                                           object:self 
                                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                   category,@"Category",nil]
                              ];
    
    [[NSNotificationQueue defaultQueue]  enqueueNotification:notice postingStyle:NSNotificationCoalescingOnName];

}

@end
