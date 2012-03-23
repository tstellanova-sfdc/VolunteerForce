//
//  ActivityCheckinVC.m
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import "ActivityCheckinVC.h"

#import "AppDataModel.h"
#import "Chatterator.h"
#import "ModalNetworkActionVC.h"
#import "SFOAuthCoordinator.h"
#import "SFOAuthCredentials.h"
#import "SFRestAPI+Blocks.h"

typedef enum {
    TimeColumn_Hour_Digit = 0,
    TimeColumn_Hour_Label = 1,
    TimeColumn_Minute_Digit = 2,
    TimeColumn_Minute_Label = 3,
    TimeColumn_Count
    
} ETimeColumns;

@implementation ActivityCheckinVC

@synthesize activityModel = _activityModel;
@synthesize participantDuration = _participantDuration;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _minutesArray = [[NSArray alloc] initWithObjects:@"0", @"15",@"30",@"45",nil];
    }
    return self;
}

- (id)initWithFullActivity:(NSDictionary*)activity 
{
    self = [self initWithNibName:@"ActivityCheckinVC" bundle:nil];
    if (self) {
        self.activityModel = activity;
        
        self.participantDuration = [NSNumber numberWithFloat:1.0];
        NSNumber *duration = [self.activityModel valueForKey:kVolunteerActivity_DurationField];
        if (![[NSNull null] isEqual:duration]) {
            self.participantDuration = duration;
        }
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
    [self updateFromModel];

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



- (void)updateFromModel {
    [self setTitle:@"Duration"];
    
    NSInteger totalMinutes = [self.participantDuration doubleValue] * 60;
    NSInteger hours = totalMinutes / 60;
    NSInteger minutes = totalMinutes % 60;

    [_durationPicker  selectRow:hours inComponent:TimeColumn_Hour_Digit animated:NO];
    NSInteger minutesIdx = minutes / (60 / [_minutesArray count]);
    [_durationPicker  selectRow:minutesIdx inComponent:TimeColumn_Minute_Digit animated:NO];
}


#pragma mark - UIPickerViewDataSource
 // returns the number of 'columns' to display.
 - (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView 
 {
     return TimeColumn_Count;
 }
 
 // returns the # of rows in each component..
 - (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (component) {
        case TimeColumn_Hour_Digit:
            return 12;
        case TimeColumn_Hour_Label:
            return 1;
        case TimeColumn_Minute_Digit:
            return [_minutesArray count];
        case TimeColumn_Minute_Label:
            return 1;
    }

    return 0;
}
 
#pragma mark - UIPickerViewDelegate


 
 // these methods return either a plain UIString, or a view (e.g UILabel) to display the row for the component.
 // for the view versions, we cache any hidden and thus unused views and pass them back for reuse. 
 // If you return back a different object, the old one will be released. the view will be centered in the row rect  
 - (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    
    switch (component) {
        case TimeColumn_Hour_Digit:
            return [NSString stringWithFormat:@"%d",row];
        case TimeColumn_Hour_Label:
            return @"hour";
        case TimeColumn_Minute_Digit:
            return [_minutesArray objectAtIndex:row];
        case TimeColumn_Minute_Label:
            return @"mins";
    }
    
    return @"Bogus";
}


#pragma mark - Private

- (SFRestRequest *)buildChatterPostForActivity:(NSDictionary*)activity 
{
    
    SFOAuthCredentials *myCreds = [[[SFRestAPI sharedInstance] coordinator] credentials];
    NSString *activityId = [activity objectForKey:@"Id"];

    ///feeds/news/me/feed-items?text=Did+you+see+this?&url=http://www.chatter.com
    ///services/data/v23.0/chatter/feeds/news/00530000001rEfbAAE/feed-items
    NSString *activityName = [activity objectForKey:@"Name"];
    NSDictionary *activityAcct = [activity objectForKey:@"Account__r"];
    NSString *acctName = [activityAcct objectForKey:@"Name"];
    
    NSString *activitySuffix = [NSString stringWithFormat:@"\"%@\" for \"%@\"",activityName,acctName];
    
    NSString *linkText = [NSString stringWithFormat:@"Volunteer with me at %@",activitySuffix];
    NSString *linkUrl = [NSString stringWithFormat:@"%@/%@",myCreds.instanceUrl,activityId];
    
    NSString *postText = [NSString stringWithFormat:@"Just volunteered at %@",activitySuffix];
    NSString *chatterPostPath = [NSString stringWithFormat:@"/%@/chatter/feeds/news/me/feed-items",kSFRestDefaultAPIVersion];
    
    NSDictionary *textSegment = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"Text",@"type",
                                 postText,@"text",
                                 nil];
    NSArray *msgSegments = [NSArray arrayWithObject:textSegment];
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          msgSegments, @"messageSegments", 
                          nil];
    NSDictionary *attachment = [NSDictionary dictionaryWithObjectsAndKeys:
                                linkUrl,@"url",
                                linkText,@"urlName",
                                nil];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            body, @"body",
                            attachment,@"attachment",
                            nil];
    
    SFRestRequest *chatterReq = [SFRestRequest requestWithMethod:SFRestMethodPOST path:chatterPostPath queryParams:params];
    return chatterReq;
}

- (IBAction)doneButtonClicked:(id)sender {
    
    //TODO pull the duration from the input
    NSInteger hours = [_durationPicker selectedRowInComponent:TimeColumn_Hour_Digit];
    NSInteger minuteIndex = [_durationPicker selectedRowInComponent:TimeColumn_Minute_Digit];
    NSString *minuteValStr = [_minutesArray objectAtIndex:minuteIndex];
    NSInteger minutes = [minuteValStr integerValue];
    NSNumber *totalHours = [NSNumber numberWithDouble:hours + (minutes / 60.0)];
    
    __block ModalNetworkActionVC *progressVC = [[ModalNetworkActionVC alloc] initWithNibName:@"ModalNetworkActionVC" bundle:nil];
        
    //pop ourselves
    [self.navigationController popViewControllerAnimated:NO];
    [self.navigationController pushViewController:progressVC animated:YES];
    
    //TODO this doesn't work because these views don't exist yet
    [progressVC setTitleText:@"Checking In"];
    [progressVC setSubtitleText:@"Please wait..."];
    
    
    //post a chatter update -- ignore success/fail
    SFRestRequest *chatterReq = [Chatterator buildChatterPostForActivityCheckin:self.activityModel];
    [[SFRestAPI sharedInstance] send:chatterReq delegate:nil];
        
    
    //kickoff the transaction
    NSString *activityId = [self.activityModel objectForKey:@"Id"];
    SFOAuthCredentials *myCreds = [[[SFRestAPI sharedInstance] coordinator] credentials];
    NSString *myUserId = myCreds.userId;
    NSDictionary *particpant = [NSDictionary dictionaryWithObjectsAndKeys:
                                activityId, @"Volunteer_Activity__c",
                                myUserId,@"User__c",
                                totalHours, kVolunteerActivity_DurationField,
                                nil];
    
    [[SFRestAPI sharedInstance]
     performCreateWithObjectType:@"Volunteer_Activity_Participant__c" 
     fields:particpant 
     failBlock:^(NSError *e) {
         NSLog(@"couldn't add participant error: %@",e);
         [progressVC setTitleText:@"Couldn't Check In"];
         [progressVC setSubtitleText:
          [NSString stringWithFormat:@"Error: %@",e]];
     } completeBlock:^(NSDictionary *dict) {
         [progressVC setTitleText:@"Success!"];
         [progressVC setSubtitleText:@"You are now confirmed for this Activity"];
         [progressVC performSelector:@selector(closeSelf) withObject:nil afterDelay:2.0];
     }
     ];
    
}



@end
