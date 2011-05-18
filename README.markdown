# Core Location Utilities#

This library provides some handy classes and extensions around iOS CoreLocation framework. 
 
## Classes ##

### CLLocationDispatch 
This class is a singleton which implements CLLocationManagerDelegate protocol. It dispatches location and heading updates to every listener that registers with it. 

Additionally, this class supports location logging. It can archive CLLocations to a file, which you can later unarchive and replay in your app using *startDemoWithLogFile:startLocationIndex:* method. 

If you have a log file in another format (e.g. KML, NMEA), you can provide an object which can read load and parse this file and implement *HGRouteProvider* to allow CLLocationDispatch to read locations from your object and dispatch them to its listeners. 

###  CLLocation(measuring)  

An extension of *CLLocation* which provides distance and direction calculations between locations and stretches (lines), defining a bounding box from a center coordinate and radius, and validating coordinate values. 

 
## How to use ##

1. Fork this repo
2. Add CoreLocationUtils folder to your project.
2. Link with CoreLocation framework. 


## License ##

CoreLocationUtils library is released under MIT License.

Please contribute your improvements and suggestions, and raise issues if you spot them.  

Thanks!  