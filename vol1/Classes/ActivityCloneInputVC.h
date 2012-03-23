//
//  ActivityCloneInputVC.h
//  vol1
//
//  Created by Todd Stellanova on 3/23/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivityCloneInputVC : UIViewController {
    NSDate *_startDateTime;
    NSDictionary *_original_Account__r;
    NSMutableDictionary *_activityModel;
    IBOutlet UIDatePicker *_dateTimePicker;
    IBOutlet UIDatePicker *_durationPicker;
    
}



@property (nonatomic, strong) NSMutableDictionary *activityModel;

- (IBAction)cloneButtonClicked:(id)sender;

- (id)initWithActivity:(NSDictionary*)activity;

- (void)updateFromModel;

@end
