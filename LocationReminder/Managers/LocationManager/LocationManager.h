
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MyAnnotation.h"

@interface LocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray    *locationMeasurements;
@property (nonatomic, strong) NSString          *currentCountry;
@property (nonatomic, strong) CLLocation		*currentLocation;
@property (nonatomic, readwrite) BOOL                       isUpdating;
@property (nonatomic,strong)	id							delegate;

#pragma mark - Instance Methods -

- (void)setupDistanceFilterWithValue: (double) value;
- (void)setupDesiredAccuracyWithAccuracy: (double) accuracy;

- (void)startUpdating;
- (void)stopUpdating;

- (void)monitorSpecificRegion:(MyAnnotation *)myAnnotation;

#pragma mark - Class Methods -

+(LocationManager *) sharedInstance;
- (BOOL)isLocationServiceEnabled;

@end

@protocol  loadTheTableViewAfterDeletion <NSObject>
@required

- (void)locationManagerDidMatchLocation: (NSDictionary *) dictionary loopCount: (int) count;
- (void)updateCurrenLocation: (CLLocation *) currentLocation;

@end