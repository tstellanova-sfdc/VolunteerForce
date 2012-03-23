//
//  AppDataModel.h
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const kVolunteerActivityType;

extern NSString * const kVolunteerActivity_DateTimeField;
extern NSString * const kVolunteerActivity_DurationField;

@interface AppDataModel : NSObject {
    NSDictionary *_Volunteer_Activity__c;
    NSArray *_recentVolunteerActivities;
    NSMutableDictionary *_fullActivitiesById;
    NSMutableDictionary *_shallowActivitiesById;
    
    NSDateFormatter *_dateTimeStringFormatter;
}


@property (nonatomic, strong) NSDictionary *Volunteer_Activity__c;
@property (nonatomic, strong, readonly) NSArray   *recentVolunteerActivities;
@property (nonatomic, strong, readonly) NSMutableDictionary *fullActivitiesById;
@property (nonatomic, strong, readonly) NSMutableDictionary *shallowActivitiesById;

- (void)addRecentVolunteerActivities:(NSArray*)recentActivities;
- (void)updateShallowActivities:(NSArray*)shallowActivities;
- (void)addFullVolunteerActivity:(NSDictionary*)activity;

- (NSDate*)dateFromDateTimeString:(NSString*)dateTimeStr;
- (NSString*)dateTimeStringFromDate:(NSDate*)date;

@end