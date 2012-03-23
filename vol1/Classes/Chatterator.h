//
//  Chatterator.h
//  vol1
//
//  Created by Todd Stellanova on 3/22/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SFRestAPI.h"

/**
 Works with SFRestAPI to create Chatter posts
 */
@interface Chatterator : NSObject




+ (SFRestRequest*)restRequestForChatterActivityPost:(NSString*)prefixText 
                                           activity:(NSDictionary*)activity;

+ (SFRestRequest *)buildChatterPostForActivityShare:(NSDictionary*)activity;
+ (SFRestRequest *)buildChatterPostForActivityCheckin:(NSDictionary*)activity;

@end
