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
    UITableViewDelegate, 
    UITableViewDataSource
    > 
{
    UITableView *_tableView;    
    DataModelSynchronizer *_syncro;

}

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, readonly) NSArray *recentActivities;
@property (nonatomic, readonly) NSArray *myActivities;


- (NSDictionary *)activityForIndexPath:(NSIndexPath*)indexPath;

@end
