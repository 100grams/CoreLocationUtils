//
//  CLLocation+measuring.h
//  StreetWise
//
//  Created by Rotem Rubnov on 4/5/2011.
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

static const double kDegreesToRadians = M_PI / 180.0;
static const double kRadiansToDegrees = 180.0 / M_PI;


/*
 *  CLCoordinateRect
 *  
 *  Discussion:
 *    A structure that contains a coordinate bounding box (rect).
 *
 *  Fields:
 *    topLeft:
 *      The coordinate at the top-left corner of the bounding box.
 *    bottomRight:
 *      The coordinate at the bottom-right corner of the bounding box.
 */
typedef struct {
	CLLocationCoordinate2D topLeft;
	CLLocationCoordinate2D bottomRight;
} CLCoordinateRect;



/*
 *  CLLocation (measuring) extension 
 *  
 *  Discussion:
 *    Adds capabilities to measure distance and direction from other locations, define bounding box, and more.
 *
 */

@interface CLLocation (measuring)

// returns the 'great-circle' distance using haversine forumla (complements the built-in distanceFromLocation:)
+ (CLLocationDistance) distanceFromCoordinate:(CLLocationCoordinate2D)fromCoord toCoordinate:(CLLocationCoordinate2D) toCoord;
- (CLLocationDistance) distanceFromCoordinate:(CLLocationCoordinate2D) toCoord;

// finds a new location on a straight line towards a second location, given distance in meters.
- (CLLocation*) newLocationAtDistance:(CLLocationDistance)distance toLocation:(CLLocation*)destination;
// identical to newLocationAtDistance:toLocation: but using coordinates
+ (CLLocationCoordinate2D) coordinateAtDistance:(CLLocationDistance)distance fromCoordinate:(CLLocationCoordinate2D)coord1 toCoordinate:(CLLocationCoordinate2D)coord2;

// returns the (2D) minimum distance from a line which connects two other locations. The projected location on that line is returned in intersection param. 
- (CLLocationDistance) distanceFromLineWithStartLocation:(CLLocation*) start endLocation:(CLLocation*) end intersection : (CLLocation**) intersection;

//returns a direction (in degrees) between the receiver and the given location 
- (CLLocationDirection)directionToLocation:(CLLocation*)location;
//returns a direction (in degrees) between an origin (from) coordinate and a destination (to) coordinate 
+ (CLLocationDirection) directionFromCoordinate:(CLLocationCoordinate2D)fromCoord toCoordinate:(CLLocationCoordinate2D) toCoord;

// returns the speed calculated from the distance and time deltas between self and fromLocation 
- (CLLocationSpeed) speedTravelledFromLocation:(CLLocation*)fromLocation;

// returns the bounding box of a circle defined by centerCoordinate and radius in meters
+ (CLCoordinateRect) boundingBoxWithCenter: (CLLocationCoordinate2D)centerCoordinate radius:(CLLocationDistance)radius;

// returns the bounding box which contains all CLLocations in locations array
+ (CLCoordinateRect) boundingBoxContainingLocations: (NSArray*)locations;

// checks if coordinate is valid and non-zero
+ (BOOL) isCoordinateValidNonZero : (CLLocationCoordinate2D) coord;

// returns a new location that will be reached after travelling from self location at 'speed' for 'duration' in 'direction'.
- (CLLocation*) newLocationAfterMovingAtSpeed:(CLLocationSpeed)speed duration:(NSTimeInterval)duration direction:(CLLocationDirection)direction;


@end
