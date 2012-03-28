/*
     File: MailComposerViewController.m
 Abstract: 
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "MailComposerViewController.h"

#import "AppDataModel.h"
#import "SFRestAPI.h"
#import "SFOAuthCoordinator.h"
#import "SFOAuthCredentials.h"

@implementation MailComposerViewController


- (void)dealloc 
{
	[super dealloc];
}


- (void)sendMailForActivity:(NSDictionary*)activity;
{
	// The MFMailComposeViewController class is only available in iPhone OS 3.0 or later. 
	// So, we must verify the existence of the above class and provide a workaround for devices running 
	// earlier versions of the iPhone OS. 
	// We display an email composition interface if MFMailComposeViewController exists and the device can send emails.
	// We launch the Mail application on the device, otherwise.
	
    // We must always check whether the current device is configured for sending emails
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if ((nil != mailClass) && [mailClass canSendMail] ){
		// We must always check whether the current device is configured for sending emails
		if ([mailClass canSendMail]) {
			[self displayComposerSheetForActivity:activity];
		}
	}

}


#pragma mark - Compose Mail




// Displays an email composition interface inside the application. Populates all the Mail fields. 
-(void)displayComposerSheetForActivity:(NSDictionary*)activity;
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
	[picker setSubject:@"Volunteer with me"];
	

    SFOAuthCredentials *myCreds = [[[SFRestAPI sharedInstance] coordinator] credentials];
    NSString *activityId = [activity objectForKey:@"Id"];
    
    NSString *activityName = [activity objectForKey:kVolunteerActivity_NameField];
    NSDictionary *activityAcct = [activity objectForKey:@"Account__r"];
    NSString *acctName = [activityAcct objectForKey:@"Name"];
    
    NSString *activitySuffix = [NSString stringWithFormat:@"\"%@\" for \"%@\"",activityName,acctName];
    
    NSString *orgActivityUrl = [NSString stringWithFormat:@"%@/%@",myCreds.instanceUrl,activityId];
    NSString *signupUrl = [NSString stringWithFormat:@"salesforce.volunteer:///activityDetail/%@",activityId];

    NSString *html = [NSString stringWithFormat:
                      @"<html>"
                      "<p>I'm volunteering at:<br/> <a href=\"%@\">%@</a></p>"
                      "<p>Use VolunteerForce for iOS to <a href=\"%@\">Join Me!</a></p>"
                      "</html",
                      orgActivityUrl, activitySuffix,
                      signupUrl];
    

    
	// Attach an image to the email
	NSString *path = [[NSBundle mainBundle] pathForResource:@"icon" ofType:@"png"];
    NSData *myData = [NSData dataWithContentsOfFile:path];
	[picker addAttachmentData:myData mimeType:@"image/png" fileName:@"volunteerIcon.png"];
	
	// Fill out the email body text
	[picker setMessageBody:html isHTML:YES];
	
	[self presentModalViewController:picker animated:YES];
    [picker release];
}


// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	[self dismissModalViewControllerAnimated:YES];
    [self.navigationController popViewControllerAnimated:NO];
}





#pragma mark - Unload views

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


@end
