//
//  ActivityCloneInputVC.m
//  vol1
//
//  Created by Todd Stellanova on 3/23/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import "ActivityCloneInputVC.h"

#import "AppDataModel.h"
#import "AppDelegate.h"

#import "SFRestAPI+Blocks.h"

@implementation ActivityCloneInputVC

@synthesize activityModel = _activityModel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithActivity:(NSDictionary*)activity 
{
    self = [self initWithNibName:@"ActivityCloneInputVC" bundle:nil];
    if (self) {
        NSMutableDictionary *cloneActivity = [[NSMutableDictionary alloc] initWithDictionary:activity];
        //remove Id since we'll eventually insert this as a new record
        [cloneActivity removeObjectForKey:@"Id"];
        _original_Account__r = [[cloneActivity objectForKey:@"Account__r"] retain];
        [cloneActivity removeObjectForKey:@"Account__r"];
        NSString *origAcctId = [_original_Account__r objectForKey:@"Id"];
        [cloneActivity setObject:origAcctId forKey:@"Account__c"];
        self.activityModel = cloneActivity;
        [cloneActivity release];
        
        
        //set the cloned event date time to NOW
        NSString *dateTimeStr = [[[AppDelegate sharedInstance] dataModel] dateTimeStringFromDate:[NSDate date]];
        [self.activityModel setValue:dateTimeStr forKey:kVolunteerActivity_DateTimeField];

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

#pragma mark - Public

- (void)doSendCloneRecord {
    
    [[SFRestAPI sharedInstance] 
     performCreateWithObjectType:kVolunteerActivityType
     fields:self.activityModel 
    failBlock:^(NSError *e) {
        NSLog(@"couldn't create, error: %@",e);
    } 
     completeBlock:^(NSDictionary *dict) {
        NSLog(@"created: %@ ",dict);
         NSString *newRecId = [dict objectForKey:@"id"];
         [self.activityModel setObject:newRecId forKey:@"Id"];
         [self.activityModel setObject:_original_Account__r forKey:@"Account__r"];
         [self.activityModel removeObjectForKey:@"Account__c"];
         
         [[[AppDelegate sharedInstance] dataModel] addFullVolunteerActivity:self.activityModel];

           
         [self.navigationController popViewControllerAnimated:YES];
    }
     ];
    
      
    
}
- (IBAction)cloneButtonClicked:(id)sender
{
    [self doSendCloneRecord];
}

- (void)updateFromModel {
    NSString *activityDateTimeStr = [self.activityModel objectForKey:kVolunteerActivity_DateTimeField];
    NSDate *realDate = [[[AppDelegate sharedInstance] dataModel] dateFromDateTimeString:activityDateTimeStr];    
    [_dateTimePicker setDate:realDate];

    
    NSNumber *duration = [self.activityModel valueForKey:kVolunteerActivity_DurationField];
    NSTimeInterval durationVal = [duration doubleValue] * 3600;
    [_durationPicker setCountDownDuration:durationVal];
}


@end
