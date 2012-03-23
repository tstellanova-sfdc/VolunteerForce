//
//  Chatterator.m
//  vol1
//
//  Created by Todd Stellanova on 3/22/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import "Chatterator.h"

#import "AppDelegate.h"
#import "AppDataModel.h"
#import "SFOAuthCoordinator.h"
#import "SFRestAPI+Blocks.h"
#import "SFRestRequest.h"

@implementation Chatterator



+ (SFRestRequest*)restRequestForChatterActivityPost:(NSString*)prefixText 
                                           activity:(NSDictionary*)activity

{
    SFOAuthCredentials *myCreds = [[[SFRestAPI sharedInstance] coordinator] credentials];

    NSString *chatterPostPath = [NSString stringWithFormat:@"/%@/chatter/feeds/news/me/feed-items",kSFRestDefaultAPIVersion];
    
    NSDictionary *textSegment = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"Text",@"type",
                                 prefixText,@"text",
                                 nil];
    
    NSMutableArray *msgSegments = [NSMutableArray arrayWithObject:textSegment];
    
    
    
    //Segments for the Activity itself
    NSString *activityName = [activity objectForKey:@"Name"];
    NSDictionary *activityNameSeg = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"Text",@"type",
                                 activityName,@"text",
                                 nil];
    [msgSegments addObject:activityNameSeg];
    
    NSString *activityId = [activity objectForKey:@"Id"];
    NSString *activityIdUrl = [NSString stringWithFormat:@"%@/%@",myCreds.instanceUrl,activityId];
    
    NSDictionary *activityLinkSeg = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"Link",@"type",
                                 activityIdUrl,@"url",
                                 nil];
    [msgSegments addObject:activityLinkSeg];
    
    
    NSDictionary *transSeg1 = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"Text",@"type",
                                     @" for ",@"text",
                                     nil];
    [msgSegments addObject:transSeg1];
    
    
    //Segments for the Volunteer Account
    NSDictionary *activityAcct = [activity objectForKey:@"Account__r"];
    
    NSString *acctName = [activityAcct objectForKey:@"Name"];
    NSDictionary *acctNameSeg = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"Text",@"type",
                             acctName,@"text",
                             nil];
    [msgSegments addObject:acctNameSeg];
    
    NSString *acctId = [activityAcct objectForKey:@"Id"];
    NSString *acctIdUrl = [NSString stringWithFormat:@"%@/%@",myCreds.instanceUrl,acctId];
    
    NSDictionary *acctLinkSeg = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"Link",@"type",
                             acctIdUrl,@"url",
                             nil];
    [msgSegments addObject:acctLinkSeg];
    
    
    //Segment for event date and time
    
    NSString *activityDateTimeStr = [activity objectForKey:@"Date_and_Time__c"];
    NSDate *realDate = [[[AppDelegate sharedInstance] dataModel] dateFromDateTimeString:activityDateTimeStr];

    
    NSDateFormatter *writeFmt = [[NSDateFormatter alloc] init];
    [writeFmt setDateFormat:@"EEEE MMMM d, yyyy 'at' h:mm a zzz"];
    NSString *outputDate = [writeFmt  stringFromDate:realDate];
    [writeFmt release];
    
    NSDictionary *dateTimeSeg = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"Text",@"type",
                                 outputDate,@"text",
                                 nil];
    [msgSegments addObject:dateTimeSeg];
    
    //Segment for hashtag
    
    NSDictionary *hashSeg = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"Hashtag",@"type",
                             @"volunteerforce",@"tag",
                             nil];
    [msgSegments addObject:hashSeg];
    
    
    
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          msgSegments, @"messageSegments", 
                          nil];
    
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   body, @"body",
                                   nil];
    
    
    NSString *activitySuffix = [NSString stringWithFormat:@"\"%@\" for \"%@\"",activityName,acctName];
    NSString *linkText = [NSString stringWithFormat:@"Volunteer with me at %@",activitySuffix];
    NSString *linkUrl = [NSString stringWithFormat:@"%@/%@",myCreds.instanceUrl,activityId];
    
    NSDictionary *attachment = [NSDictionary dictionaryWithObjectsAndKeys:
                                linkUrl,@"url",
                                linkText,@"urlName",
                                nil];
    
    [params setObject:attachment forKey:@"attachment"];
    
    SFRestRequest *chatterReq = [SFRestRequest requestWithMethod:SFRestMethodPOST path:chatterPostPath queryParams:params];
    return chatterReq;
}



+ (SFRestRequest *)buildChatterPostForActivityCheckin:(NSDictionary*)activity 
{
    SFRestRequest *chatterReq = [self restRequestForChatterActivityPost:@"Just volunteered for " activity:activity];
    return chatterReq;
}

+ (SFRestRequest *)buildChatterPostForActivityShare:(NSDictionary*)activity 
{   
    SFRestRequest *chatterReq = [self restRequestForChatterActivityPost:@"I'm volunteering at " activity:activity];
    return chatterReq;
}


@end
