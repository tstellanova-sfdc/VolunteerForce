//
//  DataModelSynchronizer.m
//  VolunteerForce
//
//  Created by Todd Stellanova on 3/26/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import "DataModelSynchronizer.h"

#import "AppDataModel.h"
#import "AppDelegate.h"
#import "SFOAuthCoordinator.h"
#import "SFRestAPI+Blocks.h"


@interface DataModelSynchronizer (Private)

- (void)nextSyncStep;

@end

@implementation DataModelSynchronizer

@synthesize statusMessage = _statusMessage;
@synthesize progressPercent = _progressPercent;
@synthesize delegate = _delegate;

#pragma mark - Request building

- (void)sendDescribeActivityRequest {
    
    __block DataModelSynchronizer *me = self;

    [[SFRestAPI sharedInstance] performDescribeWithObjectType:kVolunteerActivityType 
                                                failBlock:^(NSError *e) {
                                                    NSLog(@"couldn't describe Volunteer_Activity__c: %@",e);
                                                    //complete with error
                                                    [me.delegate synchronizerDone:self anyError:e];
                                                } 
                                                completeBlock:^(NSDictionary *dict) {
                                                    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
                                                    dataModel.Volunteer_Activity__c = dict;
                                                    [me nextSyncStep];
                                                }
     ];

}

- (void)sendGetMyDonorRequest {

//getDonorForUser(Id userId) {
//    List<Contact> d = [SELECT   id, Donation_Match_Requested_This_Year__c,
//                       Volunteer_Hours_This_Year__c, Volunteer_Hours_All_Time__c,
//                       user__c, user__r.Id, user__r.Org_62_User_ID__c, user__r.department                                       
//                       FROM     Contact
//                       WHERE    user__c = :userId];
    
    
    SFOAuthCredentials *myCreds = [[[SFRestAPI sharedInstance] coordinator] credentials];
    NSString *myUserId = myCreds.userId;
    __block DataModelSynchronizer *me = self;

    
    NSString *soql = [NSString stringWithFormat:
                      @"SELECT Id, Name, Donation_Match_Requested_This_Year__c,"
                      "Volunteer_Hours_This_Year__c, Volunteer_Hours_All_Time__c,"
                      "user__c, user__r.Id, user__r.Org_62_User_ID__c, user__r.department "
                      "FROM Contact "
                      "WHERE User__c  = '%@' ",
                      myUserId];
    
    
    [[SFRestAPI sharedInstance] performSOQLQuery:soql 
                                       failBlock:^(NSError *e) {
                                           NSLog(@"couldn't describe load my Donor record: %@",e);
                                           //complete with error
                                           [me.delegate synchronizerDone:self anyError:e];
                                       }
                                   completeBlock:^(NSDictionary *dict) {
                                       AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
                                       NSArray *allRecords = [dict objectForKey:@"records"];
                                       NSDictionary *donorRecord = [allRecords objectAtIndex:0];
                                       dataModel.myDonorRecord = donorRecord;
                                       [me nextSyncStep];
                                   }
     ];

    
}
    

- (void)sendRecentActivitiesRequest {
    _recentActivitiesReq = [[SFRestAPI sharedInstance] requestForMetadataWithObjectType:kVolunteerActivityType];
    [[SFRestAPI sharedInstance] send:_recentActivitiesReq delegate:self];
}

- (void)sendMyParticpantsRequest {
    
    SFOAuthCredentials *myCreds = [[[SFRestAPI sharedInstance] coordinator] credentials];
    NSString *myUserId = myCreds.userId;
    
    
    //Activity_Partipant.Donor2.User
    
    NSString *soql = [NSString stringWithFormat:
                      @"SELECT Volunteer_Activity__r.Id, Volunteer_Activity__r.Name, Volunteer_Activity__r.Date_Time__c, Volunteer_Activity__r.Organization__r.Name "
                      "FROM Activity_Participant__c "
                      "WHERE Donor2__r.User__c  = '%@' ",
                      myUserId];
    
    _myParticipationReq = [[SFRestAPI sharedInstance] requestForQuery:soql];
    [[SFRestAPI sharedInstance] send:_myParticipationReq delegate:self];
}

- (void)sendForthcomingEventsRequest {
    NSDate *startDate = [NSDate date];
    NSString *startDateStr = [[[AppDelegate sharedInstance] dataModel] dateTimeStringFromDate:startDate];
    NSTimeInterval thirtyDays = 30 * 24 * 3600.0f;
    NSDate *endDate = [startDate dateByAddingTimeInterval:thirtyDays];
    NSString *endDateStr = [[[AppDelegate sharedInstance] dataModel] dateTimeStringFromDate:endDate];
    
    NSString *soql = [NSString stringWithFormat:
                      @"SELECT Id,Name,Date_Time__c,Organization__r.Name "
                      "FROM Volunteer_Activity__c  "
                      "WHERE (Date_Time__c > %@ AND Date_Time__c < %@) "
                      "ORDER BY Date_Time__c ASC ",
                      startDateStr,endDateStr];
    
    _forthcomingActivitiesReq = [[SFRestAPI sharedInstance] requestForQuery:soql];
    [[SFRestAPI sharedInstance] send:_forthcomingActivitiesReq delegate:self];
    
}

#pragma mark - Response handling

- (void)handleRecentActivitiesResponse:(id)jsonResponse {
    NSArray *records = [jsonResponse objectForKey:@"recentItems"];
    NSLog(@"handleRecentActivitiesResponse #records: %d", records.count);
    
    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
    [dataModel updateRecentVolunteerActivities:records];
    
    [self nextSyncStep];
}



- (void)handleParticipationResponse:(id)jsonResponse {
    NSArray *records = [jsonResponse objectForKey:@"records"];
    NSLog(@"handleParticipationResponse #records: %d", records.count);
    
    
    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
    [dataModel addMyParticpantRecords:records];
    
    [self nextSyncStep];
}

- (void)handleForthcomingResponse:(id)jsonResponse {
    NSArray *records = [jsonResponse objectForKey:@"records"];
    NSLog(@"handleForthcomingResponse #records: %d", records.count);
    
    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
    [dataModel updateForthcomingVolunteerActivities:records];
        
    [self nextSyncStep];
}

#pragma mark - SFRestAPIDelegate

- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse {
    if ([request isEqual:_recentActivitiesReq]) {
        [self handleRecentActivitiesResponse:jsonResponse];
        _recentActivitiesReq = nil;
    } else if ([_myParticipationReq isEqual:request]) {
        [self handleParticipationResponse:jsonResponse];
        _myParticipationReq = nil;
    } else if ([_forthcomingActivitiesReq isEqual:request]) {
        [self handleForthcomingResponse:jsonResponse];
        _forthcomingActivitiesReq = nil;
    }
}


- (void)request:(SFRestRequest*)request didFailLoadWithError:(NSError*)error {
    NSLog(@"request:didFailLoadWithError: %@", error);
    //add your failed error handling here
}

- (void)requestDidCancelLoad:(SFRestRequest *)request {
    NSLog(@"requestDidCancelLoad: %@", request);
    //add your failed error handling here
}

- (void)requestDidTimeout:(SFRestRequest *)request {
    NSLog(@"requestDidTimeout: %@", request);
    //add your failed error handling here
}


- (void)setProgressPercent:(float)progressPercent
{
    _progressPercent = progressPercent;
    
    if ([self.delegate respondsToSelector:@selector(synchronizer:statusUpdate:progressPercent:)]) {
        [self.delegate synchronizer:self statusUpdate:self.statusMessage progressPercent:_progressPercent];
    }
}

- (void)start {
    [self nextSyncStep];
}

- (void)nextSyncStep {
    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
    if (nil == dataModel.Volunteer_Activity__c) {
        //need to request a describe for Volunteer_Activity__c
        [self setStatusMessage:@"Describing Volunteer_Activity__c..."];
        [self setProgressPercent:0.10f];
        
        [self sendDescribeActivityRequest];
    } else if (nil == dataModel.myDonorRecord) {
        [self setStatusMessage:@"Load Donor record..."];
        [self setProgressPercent:0.25f];
        
        [self sendGetMyDonorRequest];
    } else if (nil == dataModel.recentVolunteerActivities) {
        [self setStatusMessage:@"Load recents..."];
        [self setProgressPercent:0.33f];
        
        [self sendRecentActivitiesRequest];
    } else if (nil == dataModel.myVolunteerActivities) {
        [self setStatusMessage:@"Load participations..."];
        [self setProgressPercent:0.45f];
        
        [self sendMyParticpantsRequest];
    } else if (nil == dataModel.forthcomingVolunteerActivities) {
        [self setStatusMessage:@"Load forthcoming activities..."];
        [self setProgressPercent:0.60f];
        
        [self sendForthcomingEventsRequest];
    } else {
        // done! continue
        [self setStatusMessage:@"Done syncing!"];
        [self setProgressPercent:1.0f];
        [self.delegate synchronizerDone:self anyError:nil];
    }
}


@end
