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
        if ((nil != duration) && ![[NSNull null] isEqual:duration]) {
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
    
    NSTimeInterval totalSeconds = [self.participantDuration doubleValue] * 3600.0;
    [_durationPicker setCountDownDuration:totalSeconds];
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

- (void)closeNetworkProgress:(NSNumber*)popSelf {
    [self dismissModalViewControllerAnimated:YES];
    [_networkProgressVC release]; _networkProgressVC = nil;

    if ([popSelf boolValue]) {
        //pop ourselves
        [self.navigationController popViewControllerAnimated:NO];  
    }
}


- (void)doCheckin {

    // pull the duration from the input
    NSTimeInterval durationSeconds = [_durationPicker countDownDuration];
    NSNumber *totalHours = [NSNumber numberWithDouble:(durationSeconds / 3600.0)];
    
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
    
    ModalNetworkActionVC *progressVC = _networkProgressVC;
    [[SFRestAPI sharedInstance]
     performCreateWithObjectType:@"Volunteer_Activity_Participant__c" 
     fields:particpant 
     failBlock:^(NSError *e) {
         NSLog(@"couldn't add participant error: %@",e);
         [progressVC setTitleText:@"Couldn't Check In"];
         [progressVC setSubtitleText:
          [NSString stringWithFormat:@"Error: %@",e]];
         [self performSelector:@selector(closeNetworkProgress:) 
                    withObject:[NSNumber numberWithBool:NO] 
                    afterDelay:2.0];
     } completeBlock:^(NSDictionary *dict) {
         [progressVC setTitleText:@"Success!"];
         [progressVC setSubtitleText:@"You are now confirmed for this Activity"];
         [self performSelector:@selector(closeNetworkProgress:) 
                    withObject:[NSNumber numberWithBool:YES] 
                    afterDelay:2.0];
     }
     ];

}
- (IBAction)doneButtonClicked:(id)sender {
    _networkProgressVC = [[ModalNetworkActionVC alloc] initWithNibName:@"ModalNetworkActionVC" bundle:nil];
    [_networkProgressVC setTitleText:@"Checking In"];
    [_networkProgressVC setSubtitleText:@"Please wait..."];
    
    [self presentModalViewController:_networkProgressVC animated:YES];
    [self doCheckin];
}



@end
