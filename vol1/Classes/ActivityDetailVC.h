//
//  ActivityDetailVC.h
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MKMapView;
@class CLGeocoder;
@class SFMapAnnotator;

@interface ActivityDetailVC : UIViewController <UIActionSheetDelegate>{
    NSDictionary *_activityModel;
    NSString *_activityId;
    MKMapView *_locationMap;
    CLGeocoder *_locationGeocoder;
    SFMapAnnotator *_mapAnnotator;
}



@property (nonatomic, strong) NSString *activityId;
@property (nonatomic, strong) IBOutlet UILabel *startTimeView;
@property (nonatomic, strong) IBOutlet UILabel *titleView;
@property (nonatomic, strong) IBOutlet UITextView *descriptionView;

@property (nonatomic, strong) IBOutlet UITextView *addressView;

@property (nonatomic, strong) IBOutlet UILabel *accountNameView;

@property (nonatomic, strong, readonly) IBOutlet MKMapView *locationMap;

@property (nonatomic, strong) NSDictionary *activityModel;


- (IBAction)checkinButtonClicked:(id)sender;

- (id)initWithActivityId:(NSString*)activityId;

- (void)updateFromModel;
- (NSString *)buildAddressStringFromActivityDict:(NSDictionary*)dict;

@end
