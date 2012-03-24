//
//  SFMapAnnotator.h
//  VolunteerForce
//
//  Created by Todd Stellanova on 3/23/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface SFMapAnnotation : NSObject <MKAnnotation>
{
    UIImage *_image;
    CLLocationCoordinate2D _coordinate;
}

@property (nonatomic, strong) UIImage *image;


@end

@interface SFMapAnnotator : NSObject <MKMapViewDelegate>

@end
