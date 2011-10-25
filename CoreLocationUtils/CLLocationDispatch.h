//
//  CLLocationDispatch.h
//  StreetWise
//
//  Created by Rotem Rubnov on 5/5/2011.
//  Copyright 2011 100 grams. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CLUtilsDefines.h"

// max objects to cache in memory while logging. 
// When this limit is reached, the cache is flushed into the log file, and the in-memory cache is emptied. 
#define kLogCacheSize 1024

typedef enum{
    kLocationsCache,
    kHeadingsCache
} CLLocationDispatchLogCacheType; 

@protocol HGRouteProvider <NSObject>

- (NSEnumerator*) locationEnumerator; 

@end



@interface CLLocationDispatch : NSObject <CLLocationManagerDelegate> {
    
    // location manager and listeners
    CLLocationManager *_locationManager;
    NSMutableArray *_listeners;
    
    // location data
    CLLocation *_newLocation;
    CLLocation *_oldLocation;
    CLHeading  *_newHeading; 
    
    // route demo data 
    NSTimer *_demoTimer; 
    NSEnumerator *_locationEnumerator;
    BOOL _isRunningDemo;
    
    // logging location & heading data
    NSString *_logFileNameLocations;
    NSString *_logFileNameHeadings;
    NSMutableArray *_loggedLocations;
    NSMutableArray *_locations;
    NSMutableArray *_headings;
    NSInteger _startIndexForPlayingLog;
    NSDate* playLogStartDate;

}

// the (one and only) shared LocationDelegate
+ (CLLocationDispatch*) sharedDispatch;

// direct access to location manager. Use this property to tweak location/heading accuracy etc.
@property (nonatomic, strong) IBOutlet CLLocationManager *locationManager; 

// location data, wraps real and demo locations. If a demo is running live location updates are disabled and the locations returned are read from the route demo provider. 
@property (nonatomic, strong, readonly) CLLocation *oldLocation;
@property (nonatomic, strong, readonly, getter=getNewLocation) CLLocation *newLocation;
@property (nonatomic, strong, readonly, getter=getNewHeading) CLHeading *newHeading;
// all locations receieved since _start_. This collection is reset when _stop_ is called. 
@property (nonatomic, strong, readonly) NSArray *locations;
// all headings receieved since _start_. This collection is reset when _stop_ is called. 
@property (nonatomic, strong, readonly) NSArray *headings;

// start/stop location and heading updates from CoreLocation
- (void) start;
- (void) stop;
 
// play route demo: fires location updates by reading them from a route provider at a given (fixed) interval
// this is handly if you have a proprietary log file (e.g. NMEA stream) and you implement a class which reads it and implements HGRouteProvider protocol.  
- (void) startDemoRouteWithProvider : (id<HGRouteProvider>) provider updateInterval : (NSTimeInterval) seconds;
// play Demo from a locations archive (also created by this class). startIndex: the index of the first location to read from the file.
// the timestamp of each location is used to determine when it should be read.
- (void) startDemoWithLogFile : (NSString*) logFileName startLocationIndex : (NSInteger) startIndex; 
// stop playing demo
- (void) stopDemoRoute;
    
@property (nonatomic, readonly) BOOL isRunningDemo; 

// listening to location/heading updates
- (void) addListener : (id<CLLocationManagerDelegate>) listener; 
- (void) removeListener : (id<CLLocationManagerDelegate>) listener;

// logging (archiving) locations to logFileNameLocations. Default is NO.
@property (nonatomic, assign) BOOL logLocationData;
// logging (archiving) heading to logFileNameHeadings. Default is NO.
@property (nonatomic, assign) BOOL logHeadingData;

// archive file names. If logLocationData and/or logHeadingData is set to YES and this property has not been set, it defaults to ./Documents/locations.archive and/or ./Documents/headings.archive respectively.
@property (nonatomic, strong) NSString *logFileNameLocations; 
@property (nonatomic, strong) NSString *logFileNameHeadings; 

- (void) flushLogCache:(CLLocationDispatchLogCacheType)cacheType; //use either kLocationsCache or kHeadingsCache




@end
