    //
//  CMRoute+nodes.m
//  StreetWise
//
//  Created by Rotem Rubnov on 6/5/2011.
//  Copyright 2011 100 grams. All rights reserved.
//

#import "CLLocation+routeInfo.h"
#import "CLLocation+measuring.h"


@implementation  CLLocation(routeInfo)

- (CLLocationDistance) distanceFromRoute : (NSArray*) locations nearestNodeFound : (CLLocation**)nearestRouteNode nearestLocationOnRoute : (CLLocation**) nearestLocation nodeIndexAfterIntersection:(NSInteger*)nodeIndexAfter;
{
    CLLocationDistance minDistance = kFarAway;  
    NSInteger nearestNodeIndex = NSNotFound;
    *nearestLocation = nil;
    *nearestRouteNode = nil;
    *nodeIndexAfter = NSNotFound;
    for (int i =1; i<[locations count]; i++){
        CLLocation *routeNode1 = [locations objectAtIndex:i-1];
        CLLocationDistance distance = [self distanceFromLocation:routeNode1];
        minDistance = MIN(minDistance, distance);
        if (minDistance == distance) {
            *nearestRouteNode = routeNode1;
            *nearestLocation = routeNode1;
            nearestNodeIndex = i-1;
        }
    }
    
    // also measure the distance from the lines between the nearest route node and its adjascent nodes
    CLLocation *intersection;
    if (nearestNodeIndex != NSNotFound && nearestNodeIndex>0) {
        CLLocation *routeNode2 = [locations objectAtIndex:nearestNodeIndex-1];
        CLLocationDistance distance = [self distanceFromLineWithStartLocation:*nearestRouteNode endLocation:routeNode2 intersection:&intersection];
        minDistance = MIN(minDistance, distance>=0?distance:kFarAway);
        if (minDistance == distance) {
            (*nearestLocation) = intersection;
            *nodeIndexAfter = nearestNodeIndex;
        }
    }
    if (nearestNodeIndex<[locations count]) {
        CLLocation *routeNode2 = [locations objectAtIndex:nearestNodeIndex+1];
        CLLocationDistance distance = [self distanceFromLineWithStartLocation:*nearestRouteNode endLocation:routeNode2 intersection:&intersection];
        minDistance = MIN(minDistance, distance>=0?distance:kFarAway);
        if (minDistance == distance) {
            (*nearestLocation) = intersection;
            *nodeIndexAfter = nearestNodeIndex+1;
        }
    }
    
    if(*nodeIndexAfter == NSNotFound){
        *nodeIndexAfter = nearestNodeIndex!=NSNotFound?nearestNodeIndex+1:[locations indexOfObject:*nearestRouteNode];
    }
        
    
    return minDistance;
}


@end


