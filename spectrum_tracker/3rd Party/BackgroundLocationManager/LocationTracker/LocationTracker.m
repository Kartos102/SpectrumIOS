//
//  LocationTracker.m
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location All rights reserved.
//

#import "LocationTracker.h"

#define LATITUDE @"latitude"
#define LONGITUDE @"longitude"
#define ACCURACY @"theAccuracy"

#define DISTANCE_FILTER 0
#define GPS_TRACKER_WORK_INTERVAL 600.0
#define GPS_TRACKER_WORK_DURATION 599.0
#define GPS_DEFER_DISTANCE  50.0

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@implementation LocationTracker

+ (CLLocationManager *)sharedLocationManager {
	static CLLocationManager *_locationManager;
	
	@synchronized(self) {
		if (_locationManager == nil) {
			_locationManager = [[CLLocationManager alloc] init];
            _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            _locationManager.distanceFilter = GPS_DEFER_DISTANCE;
			_locationManager.allowsBackgroundLocationUpdates = YES;
			_locationManager.pausesLocationUpdatesAutomatically = YES;
            _locationManager.activityType = CLActivityTypeAutomotiveNavigation;
		}
	}
	return _locationManager;
}

- (id)init {
	if (self==[super init]) {
        //Get the share model and also initialize myLocationArray
        self.shareModel = [LocationShareModel sharedModel];
        self.shareModel.myLocationArray = [[NSMutableArray alloc]init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
	}
	return self;
}

- (void)applicationWillResignActive {
    
    self.deferringUpdates = NO;
    [self launchLocationManager];
    
    //Use the BackgroundTaskManager to manage all the background Task
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
}

- (void) launchLocationManager {
    
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = GPS_DEFER_DISTANCE;
    locationManager.allowsBackgroundLocationUpdates = YES;
    locationManager.pausesLocationUpdatesAutomatically = YES;
    locationManager.activityType = CLActivityTypeAutomotiveNavigation;
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
}

- (void) restartLocationUpdates
{
    NSLog(@"restartLocationUpdates");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }

    [self launchLocationManager];
}

- (void)startLocationTracking {
    NSLog(@"startLocationTracking");

	if ([CLLocationManager locationServicesEnabled] == NO) {
        NSLog(@"locationServicesEnabled false");
		UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[servicesDisabledAlert show];
	} else {
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
            NSLog(@"authorizationStatus failed");
        } else {
            NSLog(@"authorizationStatus authorized");
            
            [self launchLocationManager];
        }
	}
}

- (void)stopLocationTracking {
    NSLog(@"stopLocationTracking");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
	CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
	[locationManager stopUpdatingLocation];
    self.deferringUpdates = NO;
}

#pragma mark - CLLocationManagerDelegate Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    NSLog(@"locationManager didUpdateLocations");
    
    /*
    if (!self.deferringUpdates) {
        [manager allowDeferredLocationUpdatesUntilTraveled:CLLocationDistanceMax timeout:3.0];
        self.deferringUpdates = YES;
    }*/

    for(int i=0; i<locations.count; i++){
        
        CLLocation * newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D theLocation = newLocation.coordinate;
        CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
        
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        
        if (locationAge > 50.0)
        {
            continue;
        }
        
        //Select only valid location and also location with good accuracy
        if(newLocation!=nil&&theAccuracy>0
           &&theAccuracy<2000
           &&(!(theLocation.latitude==0.0&&theLocation.longitude==0.0))){
            
            self.myLastLocation = theLocation;
            self.myLastLocationAccuracy= theAccuracy;
            
            NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
            [dict setObject:[NSNumber numberWithFloat:theLocation.latitude] forKey:LATITUDE];
            [dict setObject:[NSNumber numberWithFloat:theLocation.longitude] forKey:LONGITUDE];
            [dict setObject:[NSNumber numberWithFloat:theAccuracy] forKey:ACCURACY];
            
            //Add the vallid location with good accuracy into an array
            //Every 1 minute, I will select the best location based on accuracy and send to server
            [self.shareModel.myLocationArray addObject:dict];
        }
    }
    
    [self checkLocations];
    
    //If the timer still valid, return it (Will not run the code below)
    if (self.shareModel.timer) {
        return;
    }
    
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
    
    //Restart the locationMaanger after 15 seconds
    self.shareModel.timer = [NSTimer scheduledTimerWithTimeInterval:GPS_TRACKER_WORK_INTERVAL target:self
                                                           selector:@selector(restartLocationUpdates)
                                                           userInfo:nil
                                                            repeats:NO];
    
    //Will only stop the locationManager after some seconds, so that we can get some accurate locations
    //The location manager will only operate for some seconds to save battery
    if (self.shareModel.delayTimer) {
        [self.shareModel.delayTimer invalidate];
        self.shareModel.delayTimer = nil;
    }
    
    self.shareModel.delayTimer = [NSTimer scheduledTimerWithTimeInterval:GPS_TRACKER_WORK_DURATION target:self
                                                    selector:@selector(stopLocationDelayBySeconds)
                                                    userInfo:nil
                                                     repeats:NO];
    
}

//Stop the locationManager
-(void)stopLocationDelayBySeconds{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    [locationManager stopUpdatingLocation];
    
    NSLog(@"locationManager stop Updating after some seconds");
}

- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error
{
   // NSLog(@"locationManager error:%@",error);
    
    switch ([error code])
    {
        case kCLErrorNetwork: // general, network-related error
        {
            NSLog(@"Failed to get location. Please check your network connection.");
        }
            break;
        case kCLErrorDenied:{
            NSLog(@"Failed to get location. You have to enable the Location Service to use this App. To enable, please go to Settings->Privacy->Location Services.");
        }
            break;
        default:
        {
            
        }
            break;
    }
    
    self.deferringUpdates = NO;
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error {
    
    NSString *strLog = [NSString stringWithFormat:@"Deferring error: %@, %@", error.localizedDescription, error.localizedFailureReason];
    
//    [SVProgressHUD showInfoWithStatus:strLog];
    
    //NSLog(strLog);
    self.deferringUpdates = NO;
}

// checkLocations
- (void)checkLocations {
    
    NSLog(@"updateLocationToServer");
    
    // Find the best location from the array based on accuracy
    NSMutableDictionary * myBestLocation = [[NSMutableDictionary alloc]init];
    
    for (int i=0; i<self.shareModel.myLocationArray.count; i++) {
        NSMutableDictionary * currentLocation = [self.shareModel.myLocationArray objectAtIndex:i];
        
        if (i==0)
            myBestLocation = currentLocation;
        else {
            if([[currentLocation objectForKey:ACCURACY]floatValue]<=[[myBestLocation objectForKey:ACCURACY]floatValue]){
                myBestLocation = currentLocation;
            }
        }
    }
    NSLog(@"My Best location:%@",myBestLocation);
    
    //If the array is 0, get the last location
    //Sometimes due to network issue or unknown reason, you could not get the location during that  period, the best you can do is sending the last known location to the server
    if (self.shareModel.myLocationArray.count == 0)
    {
        NSLog(@"Unable to get location, use the last known location");

        self.myLocation = self.myLastLocation;
        self.myLocationAccuracy = self.myLastLocationAccuracy;
    }
    else {
        CLLocationCoordinate2D theBestLocation;
        theBestLocation.latitude = [[myBestLocation objectForKey:LATITUDE]floatValue];
        theBestLocation.longitude = [[myBestLocation objectForKey:LONGITUDE]floatValue];
        self.myLocation = theBestLocation;
        self.myLocationAccuracy = [[myBestLocation objectForKey:ACCURACY]floatValue];
    }
    
    NSLog(@"Posted notifcation: Latitude(%f) Longitude(%f) Accuracy(%f)",self.myLocation.latitude, self.myLocation.longitude,self.myLocationAccuracy);
    
    //TODO: Your code to send the self.myLocation and self.myLocationAccuracy to your server
    
    self.myLocationTime = [NSDate date];
    //[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_LOCATIONCHANGED object:nil];
    
    //After sending the location to the server successful, remember to clear the current array with the following code. It is to make sure that you clear up old location in the array and add the new locations from locationManager
    [self.shareModel.myLocationArray removeAllObjects];
    self.shareModel.myLocationArray = nil;
    self.shareModel.myLocationArray = [[NSMutableArray alloc] init];
}

- (BOOL)isInMyRange:(float)latitude Long:(float)longitude{
    
    return [self isInMyRange:CLLocationCoordinate2DMake(latitude, longitude) Range:20000];
}

- (BOOL)isInMyRange:(CLLocationCoordinate2D)aNewCood Range:(CLLocationDistance)aRange{

    CLLocation *_clStore = [[CLLocation alloc] initWithLatitude:aNewCood.latitude longitude:aNewCood.longitude];
    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:self.myLocation.latitude longitude:self.myLocation.longitude];
    CLLocationDistance distance = [currentLocation distanceFromLocation:_clStore];
    if (distance < aRange)
        return YES;
    return NO;
}

@end
