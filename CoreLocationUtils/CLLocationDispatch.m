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


@implementation CLLocationDispatch

@synthesize locationManager=_locationManager;
@synthesize oldLocation=_oldLocation;
@synthesize newLocation=_newLocation;
@synthesize newHeading=_newHeading;
@synthesize logLocationData; 
@synthesize logFileName=_logFileName;
@synthesize isRunningDemo=_isRunningDemo;

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
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.headingFilter = kCLHeadingFilterNone;
        _locationManager.delegate = self;   
        
        _listeners = [[NSMutableArray alloc] initWithCapacity:0];        
    }
    
    return self;
}


- (void) dealloc
{
    [self stopDemoRoute];
//    self.locationManager = nil;
    self.logFileName = nil;
    [_listeners release];
    [_newHeading release];
    [_newLocation release];
    [_oldLocation release];
    [_logFileName release];
    [_locations release];
    [super dealloc];
}


#pragma mark - Location Updates

- (void) start
{
    if (!self.isRunningDemo) {
        [_locationManager startUpdatingLocation];
        [_locationManager startUpdatingHeading];    
    }
    else{
        NSLog(@"Warning: attempt to start real location updates while demo is running has been ignored. Please stop the demo first.");
    }
}

- (void) stop
{
    [_locationManager stopUpdatingHeading];
    [_locationManager stopUpdatingLocation];
    [_newLocation release]; _newLocation = nil;
    [_oldLocation release]; _oldLocation = nil;
    [_newHeading release]; _newHeading  = nil;
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
    if (self.logLocationData && !self.isRunningDemo) { //avoid logging while reading locations from the log file
        // archive the location
        if (!_locations) {
            _locations = [[NSMutableArray alloc] initWithCapacity:512];
        }
        [_locations addObject:newLocation];
        if (!_logFileName) {
            _logFileName = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"locations.archive"] retain];
        }
        [NSKeyedArchiver archiveRootObject:_locations toFile:_logFileName];

//        NSData *logData = [[NSString stringWithFormat:@"%@", newLocation] dataUsingEncoding:NSUTF8StringEncoding];
//        NSFileHandle *fHandle = [NSFileHandle fileHandleForWritingAtPath:_logFileName];
//        [fHandle seekToEndOfFile];
//        [fHandle writeData:logData];
//        [fHandle closeFile];
    }
    
    [_oldLocation release];
    _oldLocation = [oldLocation retain];
    [_newLocation release];
    _newLocation = [newLocation retain];
    
    [_listeners enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<CLLocationManagerDelegate> listener = obj;
        if ([listener respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) {
            [listener locationManager:manager didUpdateToLocation:newLocation fromLocation:oldLocation];
        }
    }];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    [_newHeading release];
    _newHeading = [newHeading retain];
    
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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [_locations release];
    _locations = [NSKeyedUnarchiver unarchiveObjectWithFile:logFileName];
    NSDate *logStartDate = ((CLLocation*)[_locations objectAtIndex:_startIndexForPlayingLog]).timestamp;
    for (int i=_startIndexForPlayingLog; i<[_locations count]; i++) {
        [_newLocation release];
        _newLocation = [[_locations objectAtIndex:i] retain];
        NSDate *refDate = _oldLocation?_oldLocation.timestamp:logStartDate;
        NSUInteger secs = [_newLocation.timestamp timeIntervalSinceDate : refDate];
        sleep(secs);
        [self performSelectorOnMainThread:@selector(dispatchLocationUpdateOnMainThread) withObject:nil waitUntilDone:YES];
        [_oldLocation release];
        _oldLocation = [_newLocation retain];
    }
    [pool drain];
}

- (void) dispatchLocationUpdateOnMainThread 
{
    [self locationManager:_locationManager didUpdateToLocation:self.newLocation fromLocation:self.oldLocation];    
}


- (void) stopDemoRoute
{
    if (_demoTimer) {
        
        [_demoTimer invalidate];
        [_locationEnumerator release];
        _locationEnumerator = nil;
        [_demoTimer release];
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
            _locationEnumerator = [[routeProvider locationEnumerator] retain];
        }
    }
    
    CLLocation *prevLocation = _newLocation;
    CLLocation *currLocation = [[_locationEnumerator nextObject] retain];
    
    if (currLocation) {
        [self locationManager:_locationManager didUpdateToLocation:currLocation fromLocation:prevLocation];
    }
    else{
        [self stopDemoRoute];
    }
    
}


@end

