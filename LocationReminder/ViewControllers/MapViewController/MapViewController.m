//
//  InBoundAddressViewController.m
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


#import <CoreLocation/CoreLocation.h>
#import <AddressBookUI/AddressBookUI.h>
#import "MapViewController.h"

#import "ArrayManager.h"
#import "MyAnnotation.h"
#import "SVProgressHUD.h"
#import "DXAlertView.h"
#import "LocationManager.h"
#import "Constants.h"

#pragma mark - Geocoding Methods

NSString *const kInBoundSearchTextKey = @"Search Text";     /*< NSDictionary key for entered search text. Used by NSTimer userInfo.*/
const NSTimeInterval kInBoundSearchDelay = .25;

@implementation MapViewController

@synthesize delegate;
@synthesize selectedAddressString = _selectedAddressString;
@synthesize encodedPointsString = _encodedPointsString;

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Default Init Method -

- (void) viewDidLoad {
    [super viewDidLoad];
  
    [self.navigationItem setTitle:@"Select Address"];
    [optionToolBar setBarStyle:UIBarStyleDefault];
    
//    UIBarButtonItem *showUserLocationBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Use Current Location" style:UIBarButtonItemStyleDone target:self action:@selector(showUserLocationBarButtonTapped:)];
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *userTrackingBarButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:_mapView];
    
    [optionToolBar setItems:[NSArray arrayWithObjects:spacer, userTrackingBarButton, nil] animated:YES];
    
    _geocodingResults = [[NSMutableArray alloc] initWithCapacity:0];
    _geocoder = [[CLGeocoder alloc] init];
    
    UIBarButtonItem *selectAddressBarButton = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemSave                                                                                             target:self action:@selector(selectAddressBarButtonTapped:)];
    [selectAddressBarButton setTintColor:[UIColor whiteColor]];
    [self.navigationItem setRightBarButtonItem:selectAddressBarButton];
    
    self.navigationController.navigationBar.translucent = NO;
    [self.searchDisplayController.searchBar setFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
    
    _span.latitudeDelta = 1.0;
    _span.longitudeDelta = 1.0;
    
    _mapView.showsUserLocation = YES;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSMutableArray *annotationsListArray = [[ArrayManager sharedInstance] getAllReminders];
    if ([annotationsListArray count] > 0) {
        for (NSMutableDictionary *annotationDict in annotationsListArray) {
            
            NSLog(@"annotationDict is %@", annotationDict);
            
            MyAnnotation *myAnnotation = [[MyAnnotation alloc] init];
            myAnnotation.title = [annotationDict valueForKey:@"Title"];
            myAnnotation.subtitle = [annotationDict valueForKey:@"SubTitle"];
            
            CLLocationCoordinate2D center;
            center.latitude = [[annotationDict valueForKey:@"Latitude"] doubleValue];
            center.longitude = [[annotationDict valueForKey:@"Longitude"] doubleValue];
            
            myAnnotation.coordinate = center;
            
            MKCircle *overlay = [MKCircle circleWithCenterCoordinate:center radius:REGION_RADIUS];
            [_mapView addOverlay:overlay];
            [_mapView addAnnotation:myAnnotation];
            [_mapView selectAnnotation:myAnnotation animated:YES];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) geocodeFromTimer:(NSTimer *)timer {
    NSString * searchString = [timer.userInfo objectForKey:kInBoundSearchTextKey];

    // Cancel any active geocoding. Note: Cancelling calls the completion handler on the geocoder
    if (_geocoder.isGeocoding)
        [_geocoder cancelGeocode];

    [_geocoder geocodeAddressString:searchString
                completionHandler:^(NSArray *placemark, NSError *error) {
                  if (!error)
                    [self processForwardGeocodingResults:placemark];
    }];
}
                  
- (void) processForwardGeocodingResults:(NSArray *)placemarks {
    [_geocodingResults removeAllObjects];
    [_geocodingResults addObjectsFromArray:placemarks];

    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void) didLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {

        // convert the touch point to a CLLocationCoordinate & geocode
        CGPoint touchPoint = [gesture locationInView:_mapView];
        CLLocationCoordinate2D coord = [_mapView convertPoint:touchPoint toCoordinateFromView:_mapView];
        
        if ([[ArrayManager sharedInstance] isNetworkReachable]) {
            [SVProgressHUD showWithStatus:@"Determining Location"];
            [self reverseGeocodeCoordinate:coord];
        }
        else {
            [SVProgressHUD showErrorWithStatus:INTERNET_ERROR];
        }
    }
}

- (void) reverseGeocodeCoordinate:(CLLocationCoordinate2D)coord {
    if ([_geocoder isGeocoding])
        [_geocoder cancelGeocode];
  
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    [_geocoder reverseGeocodeLocation:location
                  completionHandler:^(NSArray *placemarks, NSError *error) {
                    if (!error)
                      [self processReverseGeocodingResults:placemarks];
                  }];
}

- (void) processReverseGeocodingResults:(NSArray *)placemarks {
    if ([placemarks count] == 0)
        return;
  
    CLPlacemark * placemark = [placemarks objectAtIndex:0];
    [self addPinAnnotationForPlacemark:placemark];
}

- (void) addPinAnnotationForPlacemark:(CLPlacemark*)placemark {
    DXAlertView *alert = [[DXAlertView alloc] initWithTitle:@"Add Reminder" contentText:@"Do you want to add this location in the reminder list." leftButtonTitle:@"Cancel" rightButtonTitle:@"Ok"];
    [alert show];
    alert.leftBlock = ^() {
        NSLog(@"left button clicked");
    };
    alert.rightBlock = ^() {
        NSLog(@"right button clicked");
        MyAnnotation* myAnnotation = [[MyAnnotation alloc] init];
        myAnnotation.coordinate = placemark.location.coordinate;
        myAnnotation.title = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
        
        MKCircle *overlay = [MKCircle circleWithCenterCoordinate:myAnnotation.coordinate radius:REGION_RADIUS];
        [_mapView addOverlay:overlay];
        [_mapView addAnnotation:myAnnotation];
        [_mapView selectAnnotation:myAnnotation animated:YES];
        _selectedAddressString =  ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
        
        [self addAddressToArray:myAnnotation];
    };
    alert.dismissBlock = ^() {
        NSLog(@"Do something interesting after dismiss block");
    };
    
    [SVProgressHUD dismiss];
}

- (void) zoomMapToPlacemark:(CLPlacemark *)selectedPlacemark {
    CLLocationCoordinate2D coordinate = selectedPlacemark.location.coordinate;
    MKMapPoint mapPoint = MKMapPointForCoordinate(coordinate);
    
    double radius = (MKMapPointsPerMeterAtLatitude(coordinate.latitude) * [(CLCircularRegion*)selectedPlacemark.region radius])/2;

    MKMapSize size = {radius, radius};
    MKMapRect mapRect = {mapPoint, size};
    mapRect = MKMapRectOffset(mapRect, -radius/2, -radius/2); // adjust the rect so the coordinate is in the middle
    [_mapView setVisibleMapRect:mapRect animated:YES];
}

#pragma mark - UISearchDisplayControllerDelegate Methods -

-(void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        CGRect statusBarFrame =  [[UIApplication sharedApplication] statusBarFrame];
        CGRect frame = controller.searchBar.frame;
        frame.origin.y += statusBarFrame.size.height;
        controller.searchBar.frame = frame;
    }
}

-(void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        CGRect statusBarFrame =  [[UIApplication sharedApplication] statusBarFrame];
        CGRect frame = controller.searchBar.frame;
        frame.origin.y -= statusBarFrame.size.height;
        controller.searchBar.frame = frame;
    }
}

- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    // Use a timer to only start geocoding when the user stops typing
    if ([_searchTimer isValid])
        [_searchTimer invalidate];
   
    NSDictionary * userInfo = [NSDictionary dictionaryWithObject:searchString forKey:kInBoundSearchTextKey];
    _searchTimer = [NSTimer scheduledTimerWithTimeInterval:kInBoundSearchDelay target:self selector:@selector(geocodeFromTimer:)
                                                userInfo:userInfo repeats:NO];
    return NO;
}

#pragma mark - UITableViewDataSource Methods -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_geocodingResults count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    //'UITableView dataSource must return a cell from tableView:cellForRowAtIndexPath:'
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    CLPlacemark *placemark = [_geocodingResults objectAtIndex:indexPath.row];
    NSString *formattedAddress = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
    cell.textLabel.text = formattedAddress;

    return cell;
}

#pragma mark - UITableViewDelegate Methods -

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Clear the map
    //[_mapView removeAnnotations:_mapView.annotations];
  
    CLPlacemark * selectedPlacemark = [_geocodingResults objectAtIndex:indexPath.row];
    [self addPinAnnotationForPlacemark:selectedPlacemark];
    [self zoomMapToPlacemark:selectedPlacemark];

    // hide the search display controller and reset the search results
    [self.searchDisplayController setActive:NO animated:YES];
    [_geocodingResults removeAllObjects];
}

- (IBAction)moveToCurrentLocation:(id)sender {
	[_mapView setCenterCoordinate:[_mapView.userLocation coordinate] animated:YES];
}

#pragma mark - MKMapView Delegate Methods -

- (MKOverlayView *)mapView:(MKMapView *)map viewForOverlay:(id <MKOverlay>)overlay {
    MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    circleView.strokeColor = [UIColor darkGrayColor];
    circleView.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.4];
    return circleView;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	// if it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
	// try to dequeue an existing pin view first
	static NSString *AnnotationIdentifier = @"AnnotationIdentifier";
	MKPinAnnotationView* pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
    
	pinView.animatesDrop = YES;
	pinView.canShowCallout = YES;
	pinView.pinColor = MKPinAnnotationColorPurple;
	return pinView;
}

#pragma mark - Button Action Methods -

-(IBAction) selectAddressBarButtonTapped:(id)sender {
    if(_selectedAddressString != nil) {
        [delegate selectedDestinationAddress:_selectedAddressString forKey:@"From"];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        DXAlertView *alert = [[DXAlertView alloc] initWithTitle:@"Error" contentText:@"Please select an address." leftButtonTitle:nil rightButtonTitle:@"Ok"];
        [alert show];
        alert.leftBlock = ^() {
            NSLog(@"left button clicked");
        };
        alert.rightBlock = ^() {
            NSLog(@"right button clicked");
        };
        alert.dismissBlock = ^() {
            NSLog(@"Do something interesting after dismiss block");
        };
    }
}

-(IBAction) showUserLocationBarButtonTapped:(id)sender {
    NSLog(@"showUserLocationBarButtonTapped");
    
    double delayInSeconds = 3.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //code to be executed on the main queue after delay
        CLLocation *userLoc = _mapView.userLocation.location;
        CLLocationCoordinate2D userCoordinate = userLoc.coordinate;
        if (userCoordinate.latitude && userCoordinate.longitude !=  0.0) {
            [self reverseGeocodeCoordinate:userCoordinate];
        }
    });
}

-(IBAction) deleteAnnotationButtonTapped:(id)sender {
    NSLog(@"deleteAnnotationButtonTapped");
}

#pragma mark - Class Instance Method -

- (void) addAddressToArray:(MyAnnotation *)myAnnotation {
    NSString *latitudeString = [NSString stringWithFormat:@"%f", myAnnotation.coordinate.latitude];
    NSString *longitudeString = [NSString stringWithFormat:@"%f", myAnnotation.coordinate.longitude];
    
    NSMutableDictionary *reminderDict = [NSMutableDictionary new];
    [reminderDict setValue:myAnnotation.title forKey:@"Title"];
    [reminderDict setValue:myAnnotation.subtitle forKey:@"SubTitle"];
    [reminderDict setValue:latitudeString forKey:@"Latitude"];
    [reminderDict setValue:longitudeString forKey:@"Longitude"];
    [reminderDict setObject:[NSNumber numberWithBool:NO] forKey:@"boolForRegion"];
    
    [[LocationManager sharedInstance] monitorSpecificRegion:myAnnotation];
   [[ArrayManager sharedInstance] saveReminderToFile:reminderDict];
}

- (void) removeAddressFromArray:(MyAnnotation *)myAnnotation {
   //[[ArrayManager sharedInstance].inBoundAnnotationArray removeObject:myAnnotation];
}

- (void) receiveBookingConfirmNotification:(NSNotification *) notification {
//    if ([[notification name] isEqualToString:@"receiveBookingConfirmNotification"]) {
//        NSLog (@"Successfully received receiveBookingConfirmNotification!");
//        [_mapView removeAnnotations:_mapView.annotations];
//        
//        [[ArrayManager sharedInstance].sourceAddressArray removeAllObjects];
//        [[ArrayManager sharedInstance].destinationAddressArray removeAllObjects];
//    }
}

-(void)dealloc {
    _selectedAddressString = nil;
    _encodedPointsString = nil;
}
     
@end

