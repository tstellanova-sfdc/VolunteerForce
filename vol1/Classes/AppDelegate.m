/*
 Copyright (c) 2011, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AppDelegate.h"

#import "ActivitiesOverviewListVC.h"
#import "AppDataModel.h"
#import "ActivityDetailVC.h"
#import "RootViewController.h"

/*
 NOTE if you ever need to update these, you can obtain them from your Salesforce org,
 (When you are logged in as an org administrator, go to Setup -> Develop -> Remote Access -> New )
 */


// Fill these in when creating a new Remote Access client on Force.com 
static NSString *const RemoteAccessConsumerKey = @"3MVG99OxTyEMCQ3h7DCqShuXN_Vgn9GBqTLZFHc59vyNw8reUQJwkRoE16ePm10R_xmOWsd2VKS7U83.g7I84";
static NSString *const OAuthRedirectURI = @"volunteersfdc:///mobilesdk/detect/oauth/done"; 


@implementation AppDelegate


@synthesize dataModel = _dataModel;

+ (AppDelegate*)sharedInstance {
    id sharedDelegate = [[UIApplication sharedApplication] delegate];
    return sharedDelegate;
}




- (void)login {
    
    [_networkStatusAlert dismissWithClickedButtonIndex:-1 animated:NO];
    [_networkStatusAlert release]; _networkStatusAlert = nil;
    
    [super login];
        
}



- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didFailWithError:(NSError *)error {
    NSLog(@"oauthCoordinator:didFailWithError: %@", error);
    [coordinator.view removeFromSuperview];
    
    if (error.code == kSFOAuthErrorInvalidGrant) {  //invalid cached refresh token
        
        NSString *errorDesc = [error localizedDescription];

        //detect: ip restricted or invalid login hours
        NSRange found = [errorDesc rangeOfString:@"ip restricted or invalid login hours"];
        if (found.location != NSNotFound) {
            _networkStatusAlert = [[UIAlertView alloc] initWithTitle:@"VPN Inactive" 
                                                             message:@"In order to use this application you must be connected to the Salesforce.com internal network using VPN." 
                                                            delegate:nil 
                                                   cancelButtonTitle:nil 
                                                   otherButtonTitles:nil 
                                   ];
            [_networkStatusAlert show];
        } else {
            //restart the login process asynchronously
            NSLog(@"Logging out because oauth failed with error code: %d",error.code);
            [self performSelector:@selector(logout) withObject:nil afterDelay:0];
        }
    }
    else {
        // show alert 
        _networkStatusAlert = [[UIAlertView alloc] initWithTitle:@"Salesforce Error" 
                                                        message:[NSString stringWithFormat:@"Can't connect to salesforce: %@", error]
                                                       delegate:self
                                              cancelButtonTitle:@"Retry"
                                              otherButtonTitles: nil];
        [_networkStatusAlert show];
    }
}




- (BOOL)handleOpenURLRequest:(NSURL*)url
{
    //we currently only handle urls of the form:
    //salesforce.volunteer:///activityDetail/activityId

    NSArray *pathComps = [url pathComponents];
    NSString *cmd = [pathComps objectAtIndex:1];
    if ([cmd isEqualToString:@"activityDetail"]) {
        NSString *activityId = [pathComps objectAtIndex:2];
        [self showActivityDetail:activityId];
        return YES;
    }
    
    return NO;
}



- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self handleOpenURLRequest:url];
}



#pragma mark - Remote Access / OAuth configuration


- (NSString*)remoteAccessConsumerKey {
    return RemoteAccessConsumerKey;
}

- (NSString*)oauthRedirectURI {
    return OAuthRedirectURI;
}



#pragma mark - App lifecycle


//NOTE be sure to call all super methods you override.


- (void)clearDataModel {
    [super clearDataModel]; 
    [_dataModel release]; //throw it away
    _dataModel = [[AppDataModel alloc] init]; 
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _dataModel = [[AppDataModel alloc] init]; 
    
    NSURL *launchUrl = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if (nil != launchUrl) {
        _deferredLaunchUrl = [launchUrl copy];
    } 
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (UIViewController*)newRootViewController {
    ActivitiesOverviewListVC *eventListVC = [[ActivitiesOverviewListVC alloc] init];
    UINavigationController *rootVC = [[UINavigationController alloc] initWithRootViewController:eventListVC];
    [eventListVC release];
    
    return rootVC;
}


- (void)showHomeViewController
{
    UIViewController *navVC = [self newRootViewController];
    
    //swap in the new root view controller
    self.viewController = navVC;
    [navVC release];
    self.window.rootViewController = navVC;
    
    if (nil != _deferredLaunchUrl) {
        [self handleOpenURLRequest:_deferredLaunchUrl];
        [_deferredLaunchUrl release]; _deferredLaunchUrl = nil;
    }
}

- (void)showActivityDetail:(NSString*)activityId
{
    UINavigationController *nav = (UINavigationController*)self.viewController;
    [nav popToRootViewControllerAnimated:NO];
    ActivityDetailVC *detailVC = [[ActivityDetailVC alloc] initWithActivityId:activityId];
    [nav pushViewController:detailVC animated:YES];
    [detailVC release];
}


@end
