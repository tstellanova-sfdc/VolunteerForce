//
//  EventsListVC.m
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import "ActivitiesOverviewListVC.h"

#import "ActivityDetailVC.h"
#import "AppDelegate.h"
#import "AppDataModel.h"
#import "SFRestAPI+Blocks.h"


enum {
    ETableSection_Recents = 0,
    ETableSection_MyActivities,
    ETableSection_Count
};

@implementation ActivitiesOverviewListVC

@synthesize tableView = _tableView;

- (id)init {
    self = [self initWithNibName:@"ActivitiesOverviewListVC" bundle:nil];
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
        NSString *label =  [dataModel.Volunteer_Activity__c objectForKey:@"label"];
        self.title = label;
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Data model updates

- (void)sendRecentActivitiesRequest {

    __block ActivitiesOverviewListVC *this = self;
    [[SFRestAPI sharedInstance] 
     performMetadataWithObjectType:kVolunteerActivityType
     failBlock:^(NSError *e) {
         NSLog(@"Couldn't load recents, error: %@",e);
     }
     completeBlock:^(NSDictionary *dict) {
        NSArray *records = [dict objectForKey:@"recentItems"];
        AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
        [dataModel updateRecentVolunteerActivities:records];
        [this.tableView reloadData];
     }
    ];

}




#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self sendRecentActivitiesRequest];
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


- (NSArray *)recentActivities {
    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
    return dataModel.recentVolunteerActivities;
}

- (NSArray *)myActivities {
    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
    return dataModel.myVolunteerActivities;
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ETableSection_Count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case ETableSection_Recents:
            return @"Recent Activities";
            
        case ETableSection_MyActivities:
            return @"My Participations";
            
        default:
            return 0;
    } 
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case ETableSection_Recents:
            return [self.recentActivities count];
            
        case ETableSection_MyActivities:
            return [self.myActivities count];
            
        default:
            return 0;
    }

        
}

- (NSDictionary *)activityForIndexPath:(NSIndexPath*)indexPath {
    
    NSInteger row = [indexPath row];
    
    switch (indexPath.section) {
        case ETableSection_Recents:
            return [self.recentActivities objectAtIndex:row];
            
        case ETableSection_MyActivities:
            return [self.myActivities objectAtIndex:row];
            
        default:
            return nil;  
    }
}



// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView_ dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        
    }
	//if you want to add an image to your cell, here's how
	UIImage *image = [UIImage imageNamed:@"heart.png"];
	cell.imageView.image = image;
    
	// Configure the cell to show the data.
	NSDictionary *obj = [self activityForIndexPath:indexPath];
	cell.textLabel.text =  [obj objectForKey:@"Name"];
    
	//this adds the arrow to the right hand side.
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	return cell;
}

#pragma UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSDictionary *rowData = [self activityForIndexPath:indexPath];
    NSString *activityId = [rowData objectForKey:@"Id"];
    ActivityDetailVC *detailVC = [[ActivityDetailVC alloc] initWithActivityId:activityId];
    [self.navigationController pushViewController:detailVC animated:YES];
    [detailVC release];
}

@end
