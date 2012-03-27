//
//  SynchronizerVC.h
//  vol1
//
//  Created by Todd Stellanova on 3/21/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>



#import "DataModelSynchronizer.h"

@interface SynchronizerVC : UIViewController <DataModelSynchronizerDelegate> {

    DataModelSynchronizer *_syncro;
    
    UIProgressView *_progressView;
    UILabel *_statusView;
}


@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UILabel *statusView;

@end
