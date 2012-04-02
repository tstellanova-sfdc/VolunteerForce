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
#import "NSDictionary+NullHandling.h"
#import "SFRestAPI+Blocks.h"


enum {
    ETableSection_Recents = 0,
    ETableSection_MyActivities,
    ETableSection_AllForthcoming,

    ETableSection_Count
};

@implementation ActivitiesOverviewListVC

@synthesize tableView = _tableView;
@synthesize searchFilterText = _searchFilterText;

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
        NSString *label =  [dataModel.Volunteer_Activity__c nonNullObjectForKey:@"label"];
        if (nil == label) {
            label = @"Volunteering";
        }
        self.title = label;

        _filteredRecentActivities = [[NSMutableArray alloc] init];
        _filteredForthcomingActivities  = [[NSMutableArray alloc] init];
        _filteredMyActivities = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_filteredRecentActivities release]; _filteredRecentActivities = nil;
    [_filteredForthcomingActivities release]; _filteredForthcomingActivities = nil;
    [_filteredMyActivities release]; _filteredMyActivities = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)handleModelUpdateNotification:(NSNotification*)notice
{
    [self.tableView reloadData];
}


#pragma mark - DataModelSynchronizerDelegate

- (void)synchronizerDone:(DataModelSynchronizer*)synchronizer anyError:(NSError*)error
{
    if (nil == error) {
        [self.tableView reloadData];
        
        //register for any asynchronous model udpates that come after we've loaded a fresh set
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleModelUpdateNotification:) 
                                                     name:kAppDataModel_ModelUpdatedNotice 
                                                   object:nil
         ];
    } else {
        if ([error.domain isEqualToString:kSFRestErrorDomain]) {
            NSDictionary *userInfo = error.userInfo;
            NSString *errorCode = [userInfo objectForKey:@"errorCode"];
            if ([@"NOT_FOUND" isEqualToString:errorCode]) {
                //We can't find Volunteer_Activity__c, which means we're connected to the wrong org!
                [[AppDelegate sharedInstance] shownNonfatalErrorAlert:@"Wrong org"
                                                          message:@"Re-login to your 62 org account"];
                
                [[AppDelegate sharedInstance] logout];
            }
        }
    }
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.navigationController.navigationBar setTintColor:[UIColor orangeColor]];

    // refresh all with synchronizer
    [_syncro release];
    _syncro = [[DataModelSynchronizer alloc] init];
    [_syncro setDelegate:self];
    [_syncro start];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (NSArray *)forthcomingActivities {
    AppDataModel *dataModel = [[AppDelegate sharedInstance] dataModel];
    return dataModel.forthcomingVolunteerActivities;
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
            return @"Recent Activities";//TODO localize
            
        case ETableSection_MyActivities:
            return @"My Participation";//TODO localize
            
        case ETableSection_AllForthcoming:
            return @"Forthcoming Activities";//TODO localize

        default:
            return 0;
    } 
}

- (NSInteger)numberOfRowsInSearchFilteredSection:(NSInteger)section {
    NSInteger rowCount = 0;
        
    switch (section) {
        case ETableSection_Recents:
            rowCount = [_filteredRecentActivities count];
            break;
            
        case ETableSection_MyActivities:
            rowCount = [_filteredMyActivities count];
            break;
            
        case ETableSection_AllForthcoming:
            rowCount = [_filteredForthcomingActivities count];
            break;
    }
        
    return rowCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger rowCount = 0;

//    If the requesting table view is the search display controller's table view, return the count of
//    the filtered list, otherwise return the count of the main list.
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        rowCount = [self numberOfRowsInSearchFilteredSection:section];
    } else {
        switch (section) {
            case ETableSection_Recents:
                rowCount = [self.recentActivities count];
                if ( 0 == rowCount) {
                    rowCount = 1;
                }
                break;
                
            case ETableSection_MyActivities:
                rowCount = [self.myActivities count];
                if ( 0 == rowCount) {
                    rowCount = 1;
                }
                break;
                
            case ETableSection_AllForthcoming:
                rowCount = [self.forthcomingActivities count];
                if ( 0 == rowCount) {
                    rowCount = 1;
                }
                break;
        }
    }
    
    return rowCount;
}

- (NSDictionary *)activityForIndexPath:(NSIndexPath*)indexPath {
    
    NSDictionary *result = nil;
    NSInteger row = [indexPath row];
    NSArray *allRows = nil;
    
    switch (indexPath.section) {
        case ETableSection_Recents:
            allRows = self.recentActivities;
            if (row < [allRows count]) {
                result = [allRows objectAtIndex:row];
            }
            break;
            
        case ETableSection_MyActivities:
            allRows = self.myActivities;
            if (row < [allRows count]) {
                result = [allRows objectAtIndex:row];
            } 
            break;
            
        case ETableSection_AllForthcoming:
            allRows = self.forthcomingActivities;
            if (row < [allRows count]) {
                result = [allRows objectAtIndex:row];
            } 
            break;
    }
    
    return result;
}





// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // Dequeue or create a cell of the appropriate type.
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    
    //    If the requesting table view is the search display controller's table view, return the count of
    //    the filtered list, otherwise return the count of the main list.
	if (aTableView == self.searchDisplayController.searchResultsTableView) {
        [self inflateCell:cell withFilteredActivityAtIndexPath:indexPath];

    } else {
        [self inflateCell:cell withActivityAtIndexPath:indexPath];
    }

    
	return cell;
}



- (void)inflateCell:(UITableViewCell*)cell withActivityAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *activityModel = [self activityForIndexPath:indexPath];
    [self inflateCell:cell withActivity:activityModel];
}

- (void)inflateCell:(UITableViewCell*)cell withActivity:(NSDictionary*)activityModel
{
    if (nil != activityModel) {
        //if you want to add an image to your cell, here's how
        UIImage *image = [UIImage imageNamed:@"heart.png"];
        cell.imageView.image = image;
        
        // Configure the cell to show the data.
        cell.textLabel.text =  [activityModel objectForKey:kVolunteerActivity_NameField];
        
        //this adds the arrow to the right hand side.
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.textLabel.text = @"Loading...";//TODO localize
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.imageView.image = nil;
    }  
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSDictionary *activityModel = nil;

    if (tableView == self.searchDisplayController.searchResultsTableView) {
        activityModel = [self filteredActivityForIndexPath:indexPath];
    } else {
        activityModel = [self activityForIndexPath:indexPath];
    }
    
    if (nil != activityModel) {
        NSString *activityId = [activityModel objectForKey:@"Id"];
        ActivityDetailVC *detailVC = [[ActivityDetailVC alloc] initWithActivityId:activityId];
        [self.navigationController pushViewController:detailVC animated:YES];
        [detailVC release];
    }
}



#pragma mark - UISearchDisplayDelegate 

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if (![self.searchFilterText isEqualToString:searchString]) {
        self.searchFilterText = searchString;
        return YES;
    }
    return NO;
}


- (void)setSearchFilterText:(NSString*)text {
    if (![_searchFilterText isEqualToString:text]) {
        [_searchFilterText release];
        _searchFilterText = [text copy];
        
        [_filteredRecentActivities removeAllObjects];
        [_filteredMyActivities removeAllObjects];
        [_filteredForthcomingActivities removeAllObjects];
        
        if (nil != _searchFilterText) {
            NSArray *allRows = nil;

            allRows = self.recentActivities;
            for (NSDictionary *activity in allRows) {
                NSString *name = [activity objectForKey:kVolunteerActivity_NameField];
                NSRange found = [name rangeOfString:_searchFilterText
                                            options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)
                                 ];
                if (found.location != NSNotFound) {
                    [_filteredRecentActivities addObject:activity];
                }
            }
            
            allRows = self.myActivities;
            for (NSDictionary *activity in allRows) {
                NSString *name = [activity objectForKey:kVolunteerActivity_NameField];
                NSRange found = [name rangeOfString:_searchFilterText
                                            options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)
                                 ];
                if (found.location != NSNotFound) {
                    [_filteredMyActivities addObject:activity];
                }
            }
            
            allRows = self.forthcomingActivities;
            for (NSDictionary *activity in allRows) {
                NSString *name = [activity objectForKey:kVolunteerActivity_NameField];
                NSRange found = [name rangeOfString:_searchFilterText
                                            options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)
                                 ];
                if (found.location != NSNotFound) {
                    [_filteredForthcomingActivities addObject:activity];
                }
            }
            
        }
        
    }
}




- (void)inflateCell:(UITableViewCell*)cell withFilteredActivityAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *activityModel = [self filteredActivityForIndexPath:indexPath];
    [self inflateCell:cell withActivity:activityModel];
 
}


- (NSDictionary *)filteredActivityForIndexPath:(NSIndexPath*)indexPath {
    
    NSDictionary *result = nil;
    NSInteger row = [indexPath row];
    NSArray *allRows = nil;
    
    switch (indexPath.section) {
        case ETableSection_Recents:
            allRows = _filteredRecentActivities;
            if (row < [allRows count]) {
                result = [allRows objectAtIndex:row];
            }
            break;
            
        case ETableSection_MyActivities:
            allRows = _filteredMyActivities;
            if (row < [allRows count]) {
                result = [allRows objectAtIndex:row];
            } 
            break;
            
        case ETableSection_AllForthcoming:
            allRows = _filteredForthcomingActivities;
            if (row < [allRows count]) {
                result = [allRows objectAtIndex:row];
            } 
            break;
            
    }
    
    return result;
}


@end
