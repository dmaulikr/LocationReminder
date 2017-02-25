//
//  InBoundAddressViewController.h
//  Map Kit Demo
//
//  Created by Ryan Johnson on 3/18/12.
//  Copyright (c) 2012 mobile data solutions.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights 
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
// copies of the Software, and to permit persons to whom the Software is 
// furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in 
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
//  DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MyAnnotation.h"

@interface MapViewController : UIViewController < UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate >
{
    IBOutlet MKMapView          *_mapView;
    IBOutlet UIToolbar          *optionToolBar;
    
              NSMutableArray    *_geocodingResults;
              CLGeocoder        *_geocoder;
              NSTimer           *_searchTimer;
    
              id                delegate;
    
            NSString            *_selectedAddressString;
            NSIndexPath         *_selectedIndexPath;
}

@property (nonatomic, retain) id    delegate;

@property (nonatomic, retain) NSString *selectedAddressString;
@property (nonatomic, retain) NSString *encodedPointsString;

@property (nonatomic, assign) MKCoordinateRegion region;
@property (nonatomic, assign) MKCoordinateSpan span;
@property (nonatomic, assign) CLLocationCoordinate2D location;

- (void) geocodeFromTimer:(NSTimer *)timer;
- (void) processForwardGeocodingResults:(NSArray *)placemarks;
- (void) processReverseGeocodingResults:(NSArray *)placemarks;
- (void) reverseGeocodeCoordinate:(CLLocationCoordinate2D)coord;
- (void) addPinAnnotationForPlacemark:(CLPlacemark *)placemark;
- (void) zoomMapToPlacemark:(CLPlacemark *)selectedPlacemark;

- (IBAction) didLongPress:(UILongPressGestureRecognizer *)gr;

@end

@protocol SearchAddressViewControllerDelegate <NSObject>

-(void) selectedDestinationAddress:(NSString *)selectedDestinationAddressString forKey:(NSString *)key;
-(void) distanceBetweenAddress:(NSString *)distanceString forKey:(NSString *)key;

@end

