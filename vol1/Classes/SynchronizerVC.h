//
//  SynchronizerVC.h
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>


#import "SFRestAPI.h"



@interface SynchronizerVC : UIViewController <SFRestDelegate> {
    SFRestRequest *_recentActivitiesReq;
    SFRestRequest *_describeActivityReq;
    UIProgressView *_progressView;
    UILabel *_statusView;
}


@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UILabel *statusView;

@end
