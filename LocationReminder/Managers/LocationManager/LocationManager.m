
#import "LocationManager.h"
#import "ArrayManager.h"
#import "Constants.h"

@implementation LocationManager

#pragma mark - init Methods -

- (id)init {
    self = [super init];
    self.locationMeasurements = [NSMutableArray array];
    
    _locationManager = [[CLLocationManager alloc] init];
    [_locationManager setDelegate:self];
    [self stopMonitorSpecificRegion];
    
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locationManager requestWhenInUseAuthorization];
        [_locationManager requestAlwaysAuthorization];
    }
    
    _locationManager.distanceFilter = kCLDistanceFilterNone;							// whenever we move
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    return self;
}

+(LocationManager *) sharedInstance {
    static id singletonObject = nil;
    if(singletonObject == nil) {
        singletonObject = [[LocationManager alloc] init];
        //[singletonObject setup];
    }
    return singletonObject;
}

- (BOOL)isLocationServiceEnabled {
    return [CLLocationManager locationServicesEnabled];
}

#pragma mark - Location Manager Delegate Methods -

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *currentLocation = [locations lastObject];
    
    self.currentLocation = currentLocation;
    [self.delegate updateCurrenLocation:currentLocation];
    
    NSLog(@"ArraysManager sharedInstance] getRemindersArray in location manager is %@", [[[ArrayManager sharedInstance] getAllReminders] description]);
    
    NSInteger count = 0;
    
    for (NSMutableDictionary *annotationDict in [[[ArrayManager sharedInstance] getAllReminders] mutableCopy]) {
       NSMutableDictionary *nsmutabledictionary = [[NSMutableDictionary alloc] initWithObjects:[annotationDict allValues] forKeys:[annotationDict allKeys]];
        NSLog(@"annotationDict is %@", annotationDict);
        
        MyAnnotation *myAnnotation = [[MyAnnotation alloc] init];
        myAnnotation.title = [nsmutabledictionary valueForKey:@"Title"];
        CLLocationCoordinate2D centerCoordinate;
        centerCoordinate.latitude = [[nsmutabledictionary valueForKey:@"Latitude"] doubleValue];
        centerCoordinate.longitude = [[nsmutabledictionary valueForKey:@"Longitude"] doubleValue];
        
        CLLocationDistance regionRadius = REGION_RADIUS;
        CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:centerCoordinate radius:regionRadius
                                                                 identifier:myAnnotation.title];
        
        if (region.radius < self.locationManager.maximumRegionMonitoringDistance) {
            CLLocation *fenceCenter = [[CLLocation alloc] initWithLatitude:region.center.latitude longitude:region.center.longitude];
            
            //CLLocationAccuracy accuracy = location.horizontalAccuracy;
            CLLocationDistance d_r = [self.currentLocation distanceFromLocation:fenceCenter] - region.radius;
            NSLog(@"d_r is %f", d_r);
            
            BOOL boolForRegion = [[nsmutabledictionary objectForKey:@"boolForRegion"] boolValue];
            if (d_r < 0 && boolForRegion == NO) {
                NSLog(@"Inside the Region");
                boolForRegion = YES;
                [nsmutabledictionary setObject:[NSNumber numberWithBool:boolForRegion] forKey:@"boolForRegion"];
                [[ArrayManager sharedInstance] replaceToFile:nsmutabledictionary withIndex:count];
                
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Welcome To Region" message:@"Welcome To Region" delegate:nil
                                                          cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                }
                
                
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.timeZone = [NSTimeZone defaultTimeZone];
                localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
                localNotification.alertBody = @"Welcome To Region";
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

            }
           else if (d_r > 0 && boolForRegion == YES) {
                NSLog(@"outside the Region");
               boolForRegion = NO;
               [nsmutabledictionary setObject:[NSNumber numberWithBool:boolForRegion] forKey:@"boolForRegion"];
               [[ArrayManager sharedInstance] replaceToFile:nsmutabledictionary withIndex:count];
               
               if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Exiting From Region"
                                                                   message:@"Exiting From Region"
                                                                  delegate:nil
                                                         cancelButtonTitle:@"Ok"
                                                         otherButtonTitles:nil];
                   [alert show];
               }
               
               UILocalNotification *localNotification = [[UILocalNotification alloc] init];
               localNotification.timeZone = [NSTimeZone defaultTimeZone];
               localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
               localNotification.alertBody = @"Exiting From Region";
               [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

            }
        }
        
        count++;
    }

    
//    NSInteger count = 0;
//    CLLocation *targetLocation;
//    
//    for (NSMutableDictionary *dictionary in [[ArrayManager sharedInstance] getAllReminders]) {
//        targetLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[[dictionary valueForKey:@"Latitude"] doubleValue] longitude:(CLLocationDegrees)[[dictionary valueForKey:@"Longitude"] doubleValue]];
//        
//        NSLog(@"the new location is %@",self.currentLocation);
//        double distance = [targetLocation distanceFromLocation:self.currentLocation];
//        
//        NSLog(@"the distance is %lf",distance);
//        
//        if (distance <= LOCATION_MATCHING_RADIUS) {
//            [self.delegate locationManagerDidMatchLocation:dictionary loopCount:count];
//            break;
//        }
//        count++;
//    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    self.currentLocation = newLocation;
    [self.delegate updateCurrenLocation: newLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // The location "unknown" error simply means the manager is currently unable to get the location.
    // We can ignore this error for the scenario of getting a single location fix, because we already have a
    // timeout that will stop the location manager to save power.
    BOOL locationAllowed = [CLLocationManager locationServicesEnabled];
    
    if ([error code] != kCLErrorLocationUnknown) {
        if (locationAllowed==NO) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Service Disabled"
                                                            message:@"To re-enable, please go to Settings and turn on Location Service for this app."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        NSLog(@"the error is %ld",(long)[error code]);
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied: {
            if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                [_locationManager requestAlwaysAuthorization];
                 _locationManager.delegate = self;
            }
            else {
                [self startUpdating];
            }
            break;
        }
        case kCLAuthorizationStatusAuthorized:
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            [self stopUpdating];
            [self startUpdating];
            break;
        }
        default:
            break;
    }
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"didEnterRegion");
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Welcome To Region" message:@"Welcome To Region" delegate:nil
                                              cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
    
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    localNotification.alertBody = @"Welcome To Region";
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Exiting From Region"
                                                        message:@"Exiting From Region"
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    localNotification.alertBody = @"Exiting From Region";
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

-(void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Now monitoring for %@", region.identifier);
    
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"didStartMonitoringForRegion"
//                                                    message:@"didStartMonitoringForRegion"
//                                                   delegate:nil
//                                          cancelButtonTitle:@"Ok"
//                                          otherButtonTitles:nil];
//    [alert show];

}

- (void) locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog( @"region monitoring failed" );
    
    NSString *errorMessage = [NSString stringWithFormat:@"%@", error];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"monitoringDidFailForRegion"
                                                    message:errorMessage
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];

}

#pragma mark - Instance Methods -

- (void)setupDistanceFilterWithValue: (double) value {
    _locationManager.distanceFilter = value;
}

- (void)setupDesiredAccuracyWithAccuracy: (double) accuracy {
    _locationManager.desiredAccuracy = accuracy;
}

- (void)startUpdating {
    self.isUpdating = YES;
    _locationManager.delegate = self;
    [_locationManager startUpdatingLocation];
    [_locationManager startMonitoringSignificantLocationChanges];
}

- (void)stopUpdating {
    self.isUpdating = NO;
    [_locationManager stopUpdatingLocation];
}

- (void)stopMonitorSpecificRegion {
    NSMutableArray *annotationsListArray = [[ArrayManager sharedInstance] getAllReminders];
    if ([annotationsListArray count] > 0) {
        for (NSMutableDictionary *annotationDict in annotationsListArray) {
            
            NSLog(@"annotationDict is %@", annotationDict);
            
            MyAnnotation *myAnnotation = [[MyAnnotation alloc] init];
            myAnnotation.title = [annotationDict valueForKey:@"Title"];
            CLLocationCoordinate2D centerCoordinate;
            centerCoordinate.latitude = (CLLocationDegrees)[[annotationDict valueForKey:@"Latitude"] doubleValue];
            centerCoordinate.longitude = (CLLocationDegrees)[[annotationDict valueForKey:@"Longitude"] doubleValue];
            
            CLLocationDistance regionRadius = REGION_RADIUS;
            CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:centerCoordinate radius:regionRadius
                                                                     identifier:myAnnotation.title];
            [_locationManager stopMonitoringForRegion:region];
        }
    }
}

- (void)monitorSpecificRegion:(MyAnnotation *)myAnnotation {
    NSString *identifier = myAnnotation.title;
    CLLocationCoordinate2D centerCoordinate;
    centerCoordinate.latitude = (CLLocationDegrees)myAnnotation.coordinate.latitude;
    centerCoordinate.longitude = (CLLocationDegrees)myAnnotation.coordinate.longitude;

    CLLocationDistance regionRadius = REGION_RADIUS;
    CLCircularRegion * region = [[CLCircularRegion alloc] initWithCenter:centerCoordinate radius:regionRadius
                                                                identifier:identifier];
    [region setNotifyOnEntry:YES];
    [region setNotifyOnExit:YES];
    [_locationManager startMonitoringForRegion:region];
}

#pragma mark- DeInit Methods  -

- (void)dealloc {
} 

@end
