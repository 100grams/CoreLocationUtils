//
//  CLLocationDispatch.m
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

#import "CLLocationDispatch.h"
#import "CLLocation+measuring.h"
#import "CLLocationDeadReckoning.h"

@implementation CLLocationDispatch

@synthesize locationManager=_locationManager;
@synthesize oldLocation=_oldLocation;
@synthesize newLocation=_newLocation;
@synthesize newHeading=_newHeading;
@synthesize logLocationData, logHeadingData;
@synthesize logFileNameLocations=_logFileNameLocations;
@synthesize logFileNameHeadings=_logFileNameHeadings;
@synthesize isRunningDemo=_isRunningDemo;
@synthesize locations=_locations;
@synthesize headings=_headings;


+ (CLLocationDispatch*) sharedDispatch
{
    static CLLocationDispatch *gInstance;
    @synchronized(self)
    {
        if (gInstance == NULL)
        {
            gInstance = [[self alloc] init];            
        }
    }
    return gInstance;
}


- (id) init
{
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];

        // set app-specific locationManager properties
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        _locationManager.headingFilter = kCLHeadingFilterNone;
        _locationManager.delegate = self;
        
        _locationManager.purpose = NSLocalizedStringWithDefaultValue(@"LocationManagerPurpose", nil, [NSBundle mainBundle], @"In order to provide place search and route guidance, StreetWise needs your permission to use Location Services.", @"LocationManager purpose");
        
        _listeners = [[NSMutableArray alloc] initWithCapacity:0];        
        _isRunningDemo = NO;
    }
    
    return self;
}

#if !__has_feature(objc_arc)
- (void) dealloc
{
    [self stopDemoRoute];
//    self.locationManager = nil;
    self.logFileNameLocations = nil;
    [_listeners release];
    [_newHeading release];
    [_newLocation release];
    [_oldLocation release];
    [_logFileNameLocations release];
    [_locations release]; _locations=nil;
    [_headings release]; _headings=nil;
    [super dealloc];
}
#endif


#pragma mark - Location Updates

- (void) start
{
    BOOL enabled = [CLLocationManager locationServicesEnabled];
    //BOOL significant = [CLLocationManager significantLocationChangeMonitoringAvailable];
    BOOL authorized = YES;
    NSString *reqSysVer = @"4.2";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending){
        authorized = ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied);
    }

    if (!self.isRunningDemo && enabled && authorized) {

        // create locations cache
        if (!_locations) {
            _locations = [[NSMutableArray alloc] initWithCapacity:10];
        }
        if (!_headings) {
            _headings = [[NSMutableArray alloc] initWithCapacity:256];
        }

        [_locationManager startUpdatingLocation];
        [_locationManager startUpdatingHeading];
        
    }
    else{
        NSLog(@"Warning: attempt to start real location updates while demo is running has been ignored. Please stop the demo first.");
    }
    
    // to support DR
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deadReckoningNewLocation:) name:kNotificationNewDRLocation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deadReckoningDidStop:) name:kNotificationStoppedDR object:nil];
}

- (void) stop
{
    [_locationManager stopUpdatingHeading];
    [_locationManager stopUpdatingLocation];
    Release(_newLocation); _newLocation = nil;
    Release(_oldLocation); _oldLocation = nil;
    Release(_newHeading); _newHeading  = nil;
    
    // empty in-memory cache
    if (logHeadingData) {
        [self flushLogCache:kHeadingsCache]; 
    }
    if (logLocationData) {
        [self flushLogCache:kLocationsCache];
    }
    Release(_locations); _locations = nil;
    Release(_headings); _headings = nil;
}

- (void) addListener : (id<CLLocationManagerDelegate>) listener; 
{
    if (![_listeners containsObject:listener]) {
        [_listeners addObject:listener];
        if (_newLocation) {
            // immediately update new listener with current location
            [listener locationManager:self.isRunningDemo?nil:_locationManager  didUpdateToLocation:_newLocation fromLocation:_oldLocation];
        }
        if (_newHeading) {
            [listener locationManager:_locationManager didUpdateHeading:_newHeading];
        }
    }
}

- (void) removeListener : (id<CLLocationManagerDelegate>) listener;
{
    [_listeners removeObject:listener];
}



#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // cache & log the new location if we're not running a demo 
    if (self.logLocationData && !self.isRunningDemo) {
        // empty cache if it is full
        if ([_locations count] > kLogCacheSize) {
            [self flushLogCache:kLocationsCache];
        }
        [_locations addObject:newLocation];
    }
    
    Release(_oldLocation);
    _oldLocation = Retain(oldLocation);
    
    // verify newLocation has speed and course info, required for supporting dead-reckoning.
    CLLocationSpeed speed = newLocation.speed;
    if (speed <= 0 && self.oldLocation) {
        speed = [newLocation speedTravelledFromLocation:self.oldLocation];            
    }
    CLLocationDirection course = newLocation.course;
    if (course <= 0 && self.oldLocation) {
        course = [self.oldLocation directionToLocation:newLocation];
    }
    Release(_newLocation);
    _newLocation = [[CLLocation alloc] initWithCoordinate:newLocation.coordinate altitude:newLocation.altitude horizontalAccuracy:newLocation.horizontalAccuracy verticalAccuracy:newLocation.verticalAccuracy course:course speed:speed timestamp:newLocation.timestamp];

    //NSLog(@"new location: %@", self.newLocation);
    
    [_listeners enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<CLLocationManagerDelegate> listener = obj;
        if ([listener respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) {
            [listener locationManager:manager didUpdateToLocation:_newLocation fromLocation:_oldLocation];
        }
    }];
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if (self.logHeadingData && !self.isRunningDemo) {
        // create locations cache
        // empty cache if it is full
        if ([_headings count] > kLogCacheSize) {
            [self flushLogCache:kHeadingsCache]; 
        }
        // add the new location to the cache
        [_headings addObject:newHeading];
    }

    Release(_newHeading);
    _newHeading = Retain(newHeading);
    
    [_listeners enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<CLLocationManagerDelegate> listener = obj;
        if ([listener respondsToSelector:@selector(locationManager:didUpdateHeading:)]) {
            [listener locationManager:manager didUpdateHeading:newHeading];
        }
    }];
   
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [_listeners enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<CLLocationManagerDelegate> listener = obj;
        if ([listener respondsToSelector:@selector(locationManager:didFailWithError:)]) {
            [listener locationManager:manager didFailWithError:error];
        }
    }];
  
}

- (void) flushLogCache:(CLLocationDispatchLogCacheType)cacheType
{    
    if ( cacheType == kLocationsCache) {
        if (!_logFileNameLocations) {
            // create log file name
            _logFileNameLocations = Retain([[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"locations.archive"]);
        }
        
        NSMutableArray *allLocations = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:_logFileNameLocations]];
        if (!allLocations) {
            allLocations = [NSMutableArray arrayWithArray:_locations];
        }
        else{
            [allLocations addObjectsFromArray:_locations];            
        }
        [NSKeyedArchiver archiveRootObject:allLocations toFile:_logFileNameLocations];
        
        // clean locations cache
        [_locations removeAllObjects];
    }

    else if( cacheType == kHeadingsCache){
        if (!_logFileNameHeadings) {
            // create log file name
            _logFileNameHeadings = Retain([[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"headings.archive"]);
        }

        NSMutableArray *allHeadings = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:_logFileNameHeadings]];
        if (!allHeadings) {
            allHeadings = [NSMutableArray arrayWithArray:_headings];
        }
        else{
            [allHeadings addObjectsFromArray:_headings];            
        }
        [NSKeyedArchiver archiveRootObject:allHeadings toFile:_logFileNameHeadings];
                
        // clean headings cache
        [_headings removeAllObjects];
 
    }
         
}

#pragma mark - Dispatching Dead Reckoning Locations

- (void) deadReckoningNewLocation:(NSNotification*)notification
{
    [_listeners enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(deadReckoning:didGenerateLocation:)]) {
            CLLocationDeadReckoning *drManager = [notification object];
            [obj deadReckoning:drManager didGenerateLocation:[drManager.drLocations lastObject]];
        }
    }];

}

- (void) deadReckoningDidStop:(NSNotification*)notification
{
    [_listeners enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(deadReckoningDidStop:)]) {
            CLLocationDeadReckoning *drManager = [notification object];
            [obj deadReckoningDidStop:drManager];
        }
    }];    
}

#pragma mark - Route Demo


- (void) startDemoRouteWithProvider : (id<HGRouteProvider>) provider updateInterval : (NSTimeInterval) seconds;
{
    if (!_demoTimer) {
        // make sure live location updates are stopped (avoid interrupting the demo)
        [self stop];
        // keep heading updates running...
        [_locationManager startUpdatingHeading];    
        

        // setup location updates timer using the requested time interval
        _demoTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0] interval:seconds target:self selector:@selector(readDemoLocationFromProvider:) userInfo:[NSDictionary dictionaryWithObject:provider forKey:@"routeProvider"] repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:_demoTimer forMode:NSDefaultRunLoopMode];
        
        _isRunningDemo = YES;
    }
    else{
        NSLog(@"WARNING: attempt to start a new route demo was ignored because a demo is already running.");
    }
}


- (void) startDemoWithLogFile : (NSString*) logFileName startLocationIndex : (NSInteger) startIndex; 
{
    _startIndexForPlayingLog = startIndex>=0?startIndex:0;
    [NSThread detachNewThreadSelector:@selector(runDemoFromLogFile:) toTarget:self withObject:logFileName];  
    _isRunningDemo = YES;
}


- (void) runDemoFromLogFile : (NSString*) logFileName 
{
//    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
    @autoreleasepool {
        
        _loggedLocations = [NSKeyedUnarchiver unarchiveObjectWithFile:logFileName];
        NSDate *logStartDate = ((CLLocation*)[_loggedLocations objectAtIndex:_startIndexForPlayingLog]).timestamp;
        playLogStartDate = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval elapsedTime, prevElapsedTime=0;
        NSInteger count = [_loggedLocations count] - _startIndexForPlayingLog;
        for (int i=0; i<count; i++) {
            
            // calc the time to sleep until the next location update
            NSInteger index = i+_startIndexForPlayingLog;
            CLLocation *location = [_loggedLocations objectAtIndex:index];
            CLLocation *nextLocation = i<count-1?[_loggedLocations objectAtIndex:index+1]:nil;
            elapsedTime = [nextLocation.timestamp timeIntervalSinceDate:logStartDate];
            NSTimeInterval secs = elapsedTime - prevElapsedTime;
            prevElapsedTime = elapsedTime;
            
            // set location's timestamp to now (as in real-time location updates). This is required to keep all mechanisms 
            // which may rely on the timestamp of the location to keep the same logic as in real-time location updates (e.g. dead reckoing). 
            CLLocation *locationNow = [[CLLocation alloc] initWithCoordinate:location.coordinate altitude:location.altitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy course:location.course speed:location.speed timestamp:[NSDate dateWithTimeIntervalSinceNow:0]];
            [_loggedLocations removeObjectAtIndex:index];
            [_loggedLocations insertObject:locationNow atIndex:index];
            Release(locationNow);
            
            // dispatch the new location at index i
            [self performSelectorOnMainThread:@selector(dispatchLocationUpdateOnMainThread:) withObject:[NSNumber numberWithInt:i] waitUntilDone:YES];
            
            // in case newLocation has been modified (speed/course), retain it. 
            [_loggedLocations removeObjectAtIndex:index];
            [_loggedLocations insertObject:_newLocation atIndex:index];
            
            // sleep
            //NSLog(@"runDemoFromLogFile: going to sleep %f secs until next location update.", secs);
            usleep(secs*1000000);
            
        }
    }
//    [pool drain];
}

- (void) dispatchLocationUpdateOnMainThread:(NSNumber*)locationIndex
{
    NSInteger i = [locationIndex intValue];
    NSInteger index = i+_startIndexForPlayingLog;
    CLLocation *currLocation = [_loggedLocations objectAtIndex:index];
    CLLocation *prevLocation = i>0?[_loggedLocations objectAtIndex:index-1]:nil;
    [self locationManager:_locationManager didUpdateToLocation:currLocation fromLocation:prevLocation];    
}


- (void) stopDemoRoute
{
    if (_demoTimer) {
        
        [_demoTimer invalidate];
        Release(_locationEnumerator);
        _locationEnumerator = nil;
        Release(_demoTimer);
        _demoTimer = nil;
        NSLog(@"Route demo stopped.");
        
    }
    
    _isRunningDemo = NO;
}


- (void) readDemoLocationFromProvider : (NSTimer*)theTimer
{
    // playing demo from route provider
    if(!_locationEnumerator){
        id<HGRouteProvider> routeProvider = [[theTimer userInfo] valueForKey:@"routeProvider"];
        if (routeProvider) {
            _locationEnumerator = Retain([routeProvider locationEnumerator]);
        }
    }
    
    CLLocation *prevLocation = _newLocation;
    CLLocation *currLocation = Retain([_locationEnumerator nextObject]);
    
    if (currLocation) {
        [self locationManager:_locationManager didUpdateToLocation:currLocation fromLocation:prevLocation];
    }
    else{
        [self stopDemoRoute];
    }
    
}


@end

