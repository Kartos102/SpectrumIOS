//
//  LocationTracker.h
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LocationShareModel.h"

#define NOTIFY_LOCATIONCHANGED @"NOTIFY_LOCATIONCHANGED"

@interface LocationTracker : NSObject <CLLocationManagerDelegate>

@property (nonatomic) CLLocationCoordinate2D myLastLocation;
@property (nonatomic) CLLocationAccuracy myLastLocationAccuracy;
@property (nonatomic) BOOL deferringUpdates;

@property (strong,nonatomic) LocationShareModel * shareModel;

@property (nonatomic) CLLocationCoordinate2D myLocation;
@property (nonatomic) NSDate *myLocationTime;
@property (nonatomic) CLLocationAccuracy myLocationAccuracy;

+ (CLLocationManager *)sharedLocationManager;

- (void)startLocationTracking;
- (void)restartLocationUpdates;
- (void)stopLocationTracking;
- (void)checkLocations;

- (BOOL)isInMyRange:(CLLocationCoordinate2D)aNewCood Range:(CLLocationDistance)aRange;

@end
