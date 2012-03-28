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
    _describeActivityReq = [[SFRestAPI sharedInstance] requestForDescribeWithObjectType:kVolunteerActivityType];
    [[SFRestAPI sharedInstance] send:_describeActivityReq delegate:self];
}

- (void)sendRecentActivitiesRequest {
    _recentActivitiesReq = [[SFRestAPI sharedInstance] requestForMetadataWithObjectType:kVolunteerActivityType];
    [[SFRestAPI sharedInstance] send:_recentActivitiesReq delegate:self];
}

- (void)sendMyParticpantsRequest {
    
    SFOAuthCredentials *myCreds = [[[SFRestAPI sharedInstance] coordinator] credentials];
    NSString *myUserId = myCreds.userId;
    
    NSString *soql = [NSString stringWithFormat:
                      @"SELECT Volunteer_Activity__r.Id, Volunteer_Activity__r.Name, Volunteer_Activity__r.Date_and_Time__c, Volunteer_Activity__r.Account__r.Name "
                      "FROM Volunteer_Activity_Participant__c "
                      "WHERE User__c = '%@' ",
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
                      @"SELECT Id,Name,Date_and_Time__c,Account__r.Name "
                      "FROM Volunteer_Activity__c  "
                      "WHERE (Date_and_Time__c > %@ AND Date_and_Time__c < %@) "
                      "ORDER BY Date_and_Time__c ASC ",
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

- (void)handleDescribeActivityResponse:(id)jsonResponse {
    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
    dataModel.Volunteer_Activity__c = jsonResponse;
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
    } else if ([request isEqual:_describeActivityReq]) {
        [self handleDescribeActivityResponse:jsonResponse];
        _describeActivityReq = nil;
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
    } else if (nil == dataModel.recentVolunteerActivities) {
        [self setStatusMessage:@"Load recents..."];
        [self setProgressPercent:0.25f];
        
        [self sendRecentActivitiesRequest];
    } else if (nil == dataModel.myVolunteerActivities) {
        [self setStatusMessage:@"Load participations..."];
        [self setProgressPercent:0.40f];
        
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
