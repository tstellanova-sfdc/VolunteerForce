//
//  SynchronizerVC.m
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import "SynchronizerVC.h"

#import "AppDataModel.h"
#import "AppDelegate.h"
#import "EventsListVC.h"
#import "SFRestAPI.h"
#import "SFRestRequest.h"


@interface SynchronizerVC (Private)

- (void)nextSyncStep;

@end

@implementation SynchronizerVC

@synthesize progressView = _progressView;
@synthesize statusView = _statusView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self nextSyncStep];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Request building

- (void)sendDescribeActivityRequest {
    _describeActivityReq = [[SFRestAPI sharedInstance] requestForDescribeWithObjectType:kVolunteerActivityType];
    [[SFRestAPI sharedInstance] send:_describeActivityReq delegate:self];
}

- (void)sendRecentActivitiesRequest {
    _recentActivitiesReq = [[SFRestAPI sharedInstance] requestForMetadataWithObjectType:kVolunteerActivityType];
    [[SFRestAPI sharedInstance] send:_recentActivitiesReq delegate:self];
}

#pragma mark - Response handling

- (void)handleRecentActivitiesResponse:(id)jsonResponse {
    NSArray *records = [jsonResponse objectForKey:@"recentItems"];
    NSLog(@"handleRecentActivitiesResponse #records: %d", records.count);
    
    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
    [dataModel addRecentVolunteerActivities:records];

    [self nextSyncStep];
}

- (void)handleDescribeActivityResponse:(id)jsonResponse {
    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
    dataModel.Volunteer_Activity__c = jsonResponse;
    [self nextSyncStep];
}

#pragma mark - SFRestAPIDelegate

- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse {
    if ([request isEqual:_recentActivitiesReq]) {
        [self handleRecentActivitiesResponse:jsonResponse];
    } else if ([request isEqual:_describeActivityReq]) {
        [self handleDescribeActivityResponse:jsonResponse];
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

- (void)nextSyncStep {
    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
    if (nil == dataModel.Volunteer_Activity__c) {
        //need to request a describe for Volunteer_Activity__c
        [self.statusView setText:@"Describing Volunteer_Activity__c..."];
        [self.progressView setProgress:0.10];
        
        [self sendDescribeActivityRequest];
    } else if (nil == dataModel.recentVolunteerActivities) {
        [self.statusView setText:@"Loading recents..."];
        [self.progressView setProgress:0.25];
        
        [self sendRecentActivitiesRequest];
    } else {
        // done! continue
        [self.statusView setText:@"Done syncing!"];
        [self.progressView setProgress:0.95];
        EventsListVC *eventListVC = [[EventsListVC alloc] initWithNibName:@"EventsListVC" bundle:nil];
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:eventListVC];
        [eventListVC release];
        
        //swap in the new root view controller
        AppDelegate *app = [AppDelegate sharedInstance];
        app.viewController = navVC;
        [navVC release];
        app.window.rootViewController = navVC;

    }
}

@end
