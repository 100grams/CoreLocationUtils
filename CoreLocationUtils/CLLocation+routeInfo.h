//
//  CLLocation+routeInfo.h
//  StreetWise
//
//  Created by Rotem Rubnov on 6/5/2011.
//  Copyright 2011 100 grams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


#define kFarAway                                9999999 //9,999 km


// --------------------------------------------------------------------------------

@interface CLLocation(routeInfo)

/* 
 * Discussion:
 * Calculate the distance between the receiver and a route, provided by 'locations'.
 *
 * Parameters: 
 * locations        = the route: an NSArray of CLLocation objects
 * nearestRouteNode = when this method returns, this value contains the CLLocation in locations which is closest to the receiver.
 * nearestLocation  = when this method returns, this value contains a CLLocation which is the projection of the receiver on the route. In other words, this is the intersection point between the route and the shortest perpendicular line that starts at the receiver and intersects the route. If no such intersection exists, this value contains nil upon return.
 * nodeIndexAfter   = the index within locations array of the routeNode following nearestLocation. This may be the index of nearestRouteNode, or the one following it in locations.
 */
- (CLLocationDistance) distanceFromRoute : (NSArray*) locations nearestNodeFound : (CLLocation**)nearestRouteNode nearestLocationOnRoute : (CLLocation**) nearestLocation nodeIndexAfterIntersection:(NSInteger*)nodeIndexAfter;
@end




