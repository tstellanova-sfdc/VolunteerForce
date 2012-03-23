//
//  ActivityDetailVC.h
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivityDetailVC : UIViewController <UIActionSheetDelegate>{
    NSDictionary *_activityModel;
    NSString *_activityId;
}



@property (nonatomic, strong) NSString *activityId;
@property (nonatomic, strong) IBOutlet UILabel *startTimeView;
@property (nonatomic, strong) IBOutlet UILabel *titleView;
@property (nonatomic, strong) IBOutlet UITextView *descriptionView;

@property (nonatomic, strong) IBOutlet UITextView *addressView;

@property (nonatomic, strong) IBOutlet UILabel *accountNameView;
@property (nonatomic, strong) IBOutlet UITextView *summaryView;


@property (nonatomic, strong) NSDictionary *activityModel;


- (IBAction)checkinButtonClicked:(id)sender;

- (id)initWithActivityId:(NSString*)activityId;

- (void)updateFromModel;
- (NSString *)buildAddressStringFromActivityDict:(NSDictionary*)dict;

@end
