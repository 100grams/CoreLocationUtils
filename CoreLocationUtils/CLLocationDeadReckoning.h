//
//  CLLocationDeadReckoning.h
//  StreetWise
//
//  Created by Rotem Rubnov on 22/6/2011.
//  Copyright 2011 100 grams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

// objects should use register for this notification to get DR updates
#define kNotificationNewDRLocation @"NotificationNewDRLocation"
#define kNotificationStoppedDR     @"NotificationDRStopped"

// forward declaration
@class CLLocationDeadReckoning;


/* DeadReckoningHandler 
 * 
 * Discussion:
 * This protocol defines an interface for receiving DR locations once they are generated. 
   DR locations are dispatched by CLLocationDispatch to every listener that registers with it using addListener: method, and provided the listener adheres to this protocol.  
 */

@protocol CLLocationDeadReckoningHandler <NSObject>
- (void) deadReckoning:(CLLocationDeadReckoning*)manager didGenerateLocation:(CLLocation*)drLocation;
- (void) deadReckoningDidStop:(CLLocationDeadReckoning *)manager;
@end


/* CLLocationDeadReckoning
 * 
 * Discussion:
 * Dead Reckoning generates location updates at fixed time intervals (kDeadReckiningInterval). It helps filling in gaps between consequative location updates received from	CLLocationManager. Since DR is a science of guessing, it couldn't result in quite inaccurate results if not constrained to a a road network or a path. Therefore you can start DR only by providing a route, in the form of NSArray containing CLLocation objects.       
 *  Note (1): CLLocationDeadReckoning listens to CoreLocation updates. If CLLocationManager reports new locations at a frequency higher than kDeadReckoningInterval, DR has no effect.
 *  Note (2): to receive DR location updates, after startWithRoute: is called, you can either register for kNotificationNewDRLocation directly, or implement CLLocationDeadReckoningHandler and add your class as a listener to CLLocationDispatch. The second option is the recommended way of doing it.     
 */
 
@interface CLLocationDeadReckoning : NSObject <CLLocationManagerDelegate> {
 
    NSTimer *_locationsTimer;
    double _deceleration;
    
    NSMutableArray *_drLocations;
    
    CLLocation *_oldLocation;
    CLLocation *_newLocation;
}

// the array of DR locations which have been generated since the last hard-location was received. 
// this array is being reset whenever a new hard-location is received. 
@property (nonatomic, strong, readonly) NSArray *drLocations;

// route to follow. Dead-reckoning will generate locations along this route. This is a required property. Setting it to nil stops DR automatically. 
@property (nonatomic, copy) NSArray *followRoute;

//how often (secs) to generate soft locations? default is 1.0.
@property (nonatomic, assign) NSTimeInterval deadReckoningInterval; 

// default is -1 (do not limit). Set to a positive number to dead reckoning after maxGeneratedLocationsLimit locations have been generated. If a valid (positive) limit is set, it is reset whenever a new hard-location (from CoreLocation) is received.   
@property (nonatomic, assign) NSInteger maxGeneratedLocationsLimit; 

// start dead reckoning
- (void) startWithRoute:(NSArray*)routeToFollow;

// stop dead-reckoning
- (void) stop;

@end
