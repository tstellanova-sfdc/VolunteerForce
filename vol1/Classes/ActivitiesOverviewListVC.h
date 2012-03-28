//
//  EventsListVC.h
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>


#import "DataModelSynchronizer.h"
@interface ActivitiesOverviewListVC : UIViewController <
    DataModelSynchronizerDelegate,
    UISearchBarDelegate,
    UISearchDisplayDelegate,
    UITableViewDelegate, 
    UITableViewDataSource
    > 
{
    UITableView *_tableView;    
    DataModelSynchronizer *_syncro;
    
    NSMutableArray *_filteredRecentActivities;
    NSMutableArray *_filteredMyActivities;
    NSString *_searchFilterText;

}

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, readonly) NSArray *recentActivities;
@property (nonatomic, readonly) NSArray *myActivities;
@property (nonatomic, copy) NSString *searchFilterText;

- (NSDictionary *)activityForIndexPath:(NSIndexPath*)indexPath;

#pragma mark - Search support
- (NSDictionary *)filteredActivityForIndexPath:(NSIndexPath*)indexPath;

- (void)inflateCell:(UITableViewCell*)cell withActivity:(NSDictionary*)dict;

- (void)inflateCell:(UITableViewCell*)cell withActivityAtIndexPath:(NSIndexPath*)indexPath;
- (void)inflateCell:(UITableViewCell*)cell withFilteredActivityAtIndexPath:(NSIndexPath*)indexPath;

@end
