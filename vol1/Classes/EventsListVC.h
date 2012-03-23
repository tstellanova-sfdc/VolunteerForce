//
//  EventsListVC.h
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventsListVC : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *_tableView;    

}

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, readonly) NSArray *dataRows;

- (void)sendRecentActivitiesRequest;

@end
