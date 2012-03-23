//
//  ActivityCheckinVC.h
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ActivityCheckinVC : UIViewController <UIPickerViewDataSource,UIPickerViewDelegate> {
    IBOutlet UIPickerView *_durationPicker;
    NSArray *_minutesArray;
    NSDictionary *_activityModel;
    NSNumber *_participantDuration;
}

@property (nonatomic, strong) NSDictionary *activityModel;
@property (nonatomic, strong) NSNumber *participantDuration;

- (void)updateFromModel;

- (id)initWithFullActivity:(NSDictionary*)activity;
- (IBAction)doneButtonClicked:(id)sender;

@end
