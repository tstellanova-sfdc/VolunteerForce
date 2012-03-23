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


@implementation AppDataModel

@synthesize Volunteer_Activity__c = _Volunteer_Activity__c;
@synthesize recentVolunteerActivities = _recentVolunteerActivities;
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
    [_fullActivitiesById setObject:activity forKey:[activity objectForKey:@"Id"]];
    NSArray *acts = [NSArray arrayWithObject:activity];
    [self addRecentVolunteerActivities:acts];

}

- (void)addRecentVolunteerActivities:(NSArray*)recentActivities 
{
    [self updateShallowActivities:recentActivities];
    [_recentVolunteerActivities release];
    _recentVolunteerActivities = [[self.shallowActivitiesById allValues] retain];
}

- (void)updateShallowActivities:(NSArray*)shallowActivities
{
    for (NSDictionary *activity in shallowActivities) {
        NSString *activityId = [activity objectForKey:@"Id"];
        [self.shallowActivitiesById setObject:activity forKey:activityId];
    }
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

@end
