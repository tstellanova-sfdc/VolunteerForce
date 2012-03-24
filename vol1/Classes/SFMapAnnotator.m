//
//  SFMapAnnotator.m
//  VolunteerForce
//
//  Created by Todd Stellanova on 3/23/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import "SFMapAnnotator.h"


@implementation SFMapAnnotation

@synthesize image = _image;

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    _coordinate = newCoordinate;
}

- (CLLocationCoordinate2D) coordinate {
    return _coordinate;
}

@end

@implementation SFMapAnnotator


#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
{
    static NSString* SFMapAnnotationIdentifier = @"SFMapAnnotationIdentifier";

    MKPinAnnotationView *result = nil;
    
    if ([annotation isKindOfClass:[SFMapAnnotation class]]) {
        result = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:SFMapAnnotationIdentifier];
        if (!result) {
            result = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                     reuseIdentifier:SFMapAnnotationIdentifier];
            result.pinColor = MKPinAnnotationColorGreen;
            result.animatesDrop = NO;
            result.canShowCallout = NO;
        }        
    }
    
    return result;
}

@end
