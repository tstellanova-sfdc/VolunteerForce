//
//  ModalNetworkActionVC.m
//  vol1
//
//  Created by Todd Stellanova on 3/22/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ModalNetworkActionVC.h"

@implementation ModalNetworkActionVC

@synthesize spinner = _spinner;
@synthesize subtitleText;
@synthesize titleText;


- (id)init {
    self = [self initWithNibName:@"ModalNetworkActionVC" bundle:nil];
    return self;
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
    // status overlay
    _innerViewWrapper.layer.cornerRadius = 10.0f;
    _innerViewWrapper.layer.masksToBounds = YES;
    
    [_statusTitle setText:self.titleText];
    [_statusSubtitle setText:self.subtitleText];
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



@end
