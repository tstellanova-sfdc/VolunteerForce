//
//  DataModelSynchronizer.h
//  VolunteerForce
//
//  Created by Todd Stellanova on 3/26/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SFRestRequest.h"

//forward decl
@class DataModelSynchronizer;

@protocol  DataModelSynchronizerDelegate <NSObject>

- (void)synchronizerDone:(DataModelSynchronizer*)synchronizer anyError:(NSError*)error;

@optional
- (void)synchronizer:(DataModelSynchronizer*)synchronizer statusUpdate:(NSString*)status progressPercent:(float)progress;

@end 

@interface DataModelSynchronizer : NSObject<SFRestDelegate> {
    SFRestRequest *_recentActivitiesReq;
    SFRestRequest *_myParticipationReq;
    SFRestRequest *_forthcomingActivitiesReq;
    
    NSString *_statusMessage;
    float _progressPercent;
    id _delegate;
}

@property (nonatomic, copy) NSString *statusMessage;
@property (nonatomic, assign) float progressPercent;
@property (nonatomic, assign) id delegate;

- (void)start;


@end
