//
//  ModalNetworkActionVC.h
//  vol1
//
//  Created by Todd Stellanova on 3/22/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ModalNetworkActionVC : UIViewController {
    IBOutlet UILabel *_statusTitle;
    IBOutlet UILabel *_statusSubtitle;
    IBOutlet UIView *_innerViewWrapper;
    UIActivityIndicatorView *_spinner;
}

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, copy) NSString *subtitleText;
@property (nonatomic, copy) NSString *titleText;


@end
