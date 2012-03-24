//
//  ActivityDetailVC.m
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "ActivityDetailVC.h"

#import "ActivityCheckinVC.h"
#import "ActivityCloneInputVC.h"
#import "AppDataModel.h"
#import "AppDelegate.h"
#import "Chatterator.h"
#import "MailComposerViewController.h"
#import "SFMapAnnotator.h"
#import "SFRestAPI+Blocks.h"


enum {
    kActionSheetButtonIndexCheckIn = 0,
    kActionSheetButtonIndexClone  = 1,
    kActionSheetButtonIndexEmail   = 2,
    kActionSheetButtonIndexReChatter = 3,

    kActionSheetButtonCount

};

@implementation ActivityDetailVC

@synthesize activityModel = _activityModel;
@synthesize startTimeView;
@synthesize titleView;
@synthesize descriptionView;
@synthesize activityId = _activityId;
@synthesize addressView;
@synthesize accountNameView;
@synthesize locationMap = _locationMap;

- (id)initWithActivityId:(NSString*)activityId
{
    self = [self initWithNibName:@"ActivityDetailVC" bundle:nil];
    if (self) {
        self.title = @"Activity";
        self.activityId = activityId;
        _locationGeocoder = [[CLGeocoder alloc] init] ;
        _mapAnnotator = [[SFMapAnnotator alloc] init];

        AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
        self.activityModel = [dataModel.fullActivitiesById objectForKey:activityId];
        if (nil == self.activityModel) {
            self.activityModel = [dataModel.shallowActivitiesById objectForKey:activityId];
            // kickoff fetch of new item
            
            //prevent unintended retain
            __block ActivityDetailVC *me = self;
            
            NSArray *fieldList = [NSArray arrayWithObjects:
                                  @"Name",
                                  @"Account__r.Name", 
                                  @"Account__r.Id", 
                                  kVolunteerActivity_DateTimeField,
                                  @"Description__c",
                                  kVolunteerActivity_DurationField, 
                                  @"During_Work_Hours__c", 
                                  @"Event_Summary__c", 
                                  @"Event_takes_place_in_office__c",
                                  @"Max_Number_of_Participants__c", 
                                  @"Privacy__c", 
                                  @"Volunteer_Events__c", 
                                  @"Street__c",
                                  @"City__c",
                                  @"State_Province__c",
                                  @"Country__c",
                                  @"Zip_Postal_Code__c",
                                  nil];
            [[SFRestAPI sharedInstance]
             performRetrieveWithObjectType:kVolunteerActivityType
             objectId:activityId 
             fieldList:fieldList 
             failBlock:^(NSError *e) {
                 NSLog(@"couldn't retrieve %@ error: %@",activityId,e);
             } 
             completeBlock:^(NSDictionary *dict) {
                 NSLog(@"retrieved: %@ ",activityId);
                  me.activityModel = dict;
                 [[[[AppDelegate sharedInstance] dataModel] fullActivitiesById] setObject:dict forKey:me.activityId];
                 [me updateFromModel];
             }
            ]; 
        }
    }
    
    return self;
}

- (void)dealloc {
    [_locationGeocoder release]; _locationGeocoder = nil;
    [_mapAnnotator release]; _mapAnnotator = nil;
    [super dealloc];
}

- (NSString *)buildAddressStringFromActivityDict:(NSDictionary*)dict {
    
    NSMutableString *sb = [NSMutableString stringWithString:@""];
    NSString *street = [dict valueForKey:@"Street__c"];
    NSString *city = [dict valueForKey:@"City__c"];
    NSString *country = [dict valueForKey:@"Country__c"];
    NSString *state = [dict valueForKey:@"State_Province__c"];
    NSString *postal = [dict valueForKey:@"Zip_Postal_Code__c"];

    if ((nil != street) && ![[NSNull null] isEqual:street])
        [sb appendFormat:@"%@",street];
    
    if ((nil != city) && ![[NSNull null] isEqual:city])
        [sb appendFormat:@"\n%@",city];
    
    if ((nil != state)  && ![[NSNull null] isEqual:state])
        [sb appendFormat:@" %@",state];
    
    if ((nil != postal)  && ![[NSNull null] isEqual:postal])
        [sb appendFormat:@" %@",postal];
    
    if ((nil != country)  && ![[NSNull null] isEqual:country])
        [sb appendFormat:@"\n%@",country];
    
    return sb;
}

- (void)updateFromModel {
    [self.titleView setText:[self.activityModel objectForKey:@"Name"]];
    
    
    NSString *activityDateTimeStr = [self.activityModel objectForKey:kVolunteerActivity_DateTimeField];
    NSDate *realDate = [[[AppDelegate sharedInstance] dataModel] dateFromDateTimeString:activityDateTimeStr];

    
    NSDateFormatter *displayFmt = [[NSDateFormatter alloc] init];
    [displayFmt setDateFormat:@"EEEE MMM d, h:mma zzz"];
    NSString *displayDateTime = [displayFmt  stringFromDate:realDate];
    [displayFmt release];
    
    NSString *displayDateTimeDuration = displayDateTime;
    
    NSNumber *durationVal = [self.activityModel valueForKey:@"Duration_hours__c"];
    if (durationVal != nil) {
        displayDateTimeDuration = [NSString stringWithFormat:@"%@ -- %0.02f hr",
                                   displayDateTime,[durationVal floatValue]];
    }

    [self.startTimeView setText:displayDateTimeDuration];

    [self.locationMap setHidden:YES];
    [self.locationMap setDelegate:nil];
    
    NSString *address = [self buildAddressStringFromActivityDict:self.activityModel];    
    if ([address length] == 0) {
        address = @"Loading...";
    } else {
        __block MKMapView *mapView = self.locationMap;
        [_locationGeocoder geocodeAddressString:address 
                              completionHandler:
         ^(NSArray *placemarks, NSError *e) {
             if (nil == e) {
                 for (CLPlacemark *place in placemarks) {
                     if (nil != place.location) {
                         NSLog(@"found location: %@",place.location);
                         CLLocationCoordinate2D loc = place.location.coordinate;
                         [self.locationMap setHidden:NO];
                         [mapView setCenterCoordinate:loc];
                         [mapView setRegion:MKCoordinateRegionMake(loc,MKCoordinateSpanMake(0.007,0.007))
                                   animated:NO];
                         
                         [mapView setDelegate:_mapAnnotator];
                         SFMapAnnotation *annotation = [[SFMapAnnotation alloc] init];
                         [annotation setCoordinate:loc];
                         [mapView addAnnotation:annotation];
                         [annotation release];
                         break;
                     }
                 }
             } else {
                 NSLog(@"Error geocoding: %@",e);
             }
         }
         ];
    }
    [self.addressView setText:address];
    

    
    NSDictionary *acct = [self.activityModel objectForKey:@"Account__r"];
    if (![[NSNull null] isEqual:acct]) {
        NSString *accountTitle = [acct objectForKey:@"Name"];
        if (![[NSNull null] isEqual:accountTitle])
            [self.accountNameView setText:accountTitle];
    }
    
    NSMutableString *fullDesc = [[NSMutableString alloc] init ];
    NSString *summary = [self.activityModel objectForKey:@"Event_Summary__c"];
    if ((nil != summary) && ![[NSNull null] isEqual:summary]) {
        [fullDesc appendFormat:@"Summary:\n\n %@",summary];
    }
    
    NSString *desc = [self.activityModel objectForKey:@"Description__c"];
    if ((nil != desc) && ![[NSNull null] isEqual:desc]) {
        [fullDesc appendFormat:@"\n\nDescription:\n\n %@",desc];
    }
    [self.descriptionView setText:fullDesc];
    [fullDesc release];
    
    
}


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
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionAction:)] autorelease];
    
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

#pragma mark - Private

- (void)doCheckin
{
    ActivityCheckinVC *nextVC = [[ActivityCheckinVC alloc] initWithFullActivity:self.activityModel];                         
    [self.navigationController pushViewController:nextVC animated:YES];
    [nextVC release];
}

- (void)doReChatter {
    //post a chatter update -- ignore success/fail
    SFRestRequest *chatterReq = [Chatterator buildChatterPostForActivityShare:self.activityModel];
    [[SFRestAPI sharedInstance] send:chatterReq delegate:nil];
}

- (void)doEmailActivity {
    MailComposerViewController *mailVC = [[MailComposerViewController alloc] init];
    [self.navigationController pushViewController:mailVC animated:YES];
    [mailVC sendMailForActivity:self.activityModel];
    [mailVC release];
}

- (void)doCloneActivity {
    ActivityCloneInputVC *cloneVC = [[ActivityCloneInputVC alloc] initWithActivity:self.activityModel];
    [self.navigationController pushViewController:cloneVC animated:YES];
    [cloneVC release];
}

- (IBAction)checkinButtonClicked:(id)sender
{
    [self doCheckin];
}

// Called in response to the user tapping the Action button.  This puts up an 
// alert sheet that lets the user choose what they'd like to do.
- (IBAction)actionAction:(id)sender
{
    UIActionSheet *actionSheet = [[[UIActionSheet alloc] 
                                   initWithTitle:nil 
                                   delegate:self 
                                   cancelButtonTitle:@"Cancel" 
                                   destructiveButtonTitle:nil
                                   otherButtonTitles:
                                    @"Check-In", 
                                    @"Clone", 
                                    @"email",
                                    @"Post to Chatter", 
                                   nil
                                   ] autorelease];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {

        case   kActionSheetButtonIndexCheckIn:
            [self doCheckin];
            break;
            
        case kActionSheetButtonIndexClone:
            [self doCloneActivity];
            break;
            
        case kActionSheetButtonIndexEmail:
            [self doEmailActivity];
            break;
            
        case kActionSheetButtonIndexReChatter:
            [self doReChatter];
            break;
    }
}
            

@end
