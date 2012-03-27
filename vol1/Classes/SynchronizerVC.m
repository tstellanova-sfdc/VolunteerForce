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
#import "ActivitiesOverviewListVC.h"

#import "DataModelSynchronizer.h"
#import "SFRestAPI.h"
#import "SFRestRequest.h"




@implementation SynchronizerVC

@synthesize progressView = _progressView;
@synthesize statusView = _statusView;


- (id)init {
    self = [self initWithNibName:@"SynchronizerVC" bundle:nil];
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _syncro = [[DataModelSynchronizer alloc] init];
        [_syncro setDelegate:self];
        [_syncro start];
    }
    return self;
}

- (void)dealloc {
    [_syncro release]; _syncro = nil;
    
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


#pragma mark - DataModelSynchronizerDelegate

- (void)synchronizerDone:(DataModelSynchronizer*)synchronizer anyError:(NSError*)error
{
    ActivitiesOverviewListVC *eventListVC = [[ActivitiesOverviewListVC alloc] initWithNibName:@"ActivitiesOverviewListVC" bundle:nil];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:eventListVC];
    [eventListVC release];
    
    //swap in the new root view controller
    AppDelegate *app = [AppDelegate sharedInstance];
    app.viewController = navVC;
    [navVC release];
    app.window.rootViewController = navVC;
}


- (void)synchronizer:(DataModelSynchronizer*)synchronizer statusUpdate:(NSString*)status progressPercent:(float)progress
{
    [self.statusView setText:status];
    [self.progressView setProgress:progress];
}


@end
