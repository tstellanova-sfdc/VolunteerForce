//
//  ActivityCheckinVC.h
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ModalNetworkActionVC;

@interface ActivityCheckinVC : UIViewController  {
    IBOutlet UIDatePicker *_durationPicker;
    NSArray *_minutesArray;
    NSDictionary *_activityModel;
    NSNumber *_participantDuration;
    ModalNetworkActionVC *_networkProgressVC;
}

@property (nonatomic, strong) NSDictionary *activityModel;
@property (nonatomic, strong) NSNumber *participantDuration;

- (void)updateFromModel;

- (id)initWithFullActivity:(NSDictionary*)activity;
- (IBAction)doneButtonClicked:(id)sender;

@end
