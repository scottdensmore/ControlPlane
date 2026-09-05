//
//	CoreLocationSource.m
//	ControlPlane
//
//	Created by David Jennes on 03/09/11.
//	Copyright 2011. All rights reserved.
//
//  Code rework and improvements by Vladimir Beloborodov (VladimirTechMan) on 1 September 2013.
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import <MapKit/MapKit.h>
#import "CoreLocationSource.h"
#import "DSLogger.h"


@implementation CLLocation (CustomExtensions)

- (id)initWithText:(NSString *)text {
    NSArray *comp = [text componentsSeparatedByString:@","];
	if ([comp count] != 2) {
		return nil;
    }
	return [self initWithLatitude:[comp[0] doubleValue] longitude:[comp[1] doubleValue]];
}

- (NSString *)convertToText {
	return [NSString stringWithFormat:@"%f, %f", self.coordinate.latitude, self.coordinate.longitude];
}

@end


@implementation CoreLocationSource {
	CLLocationManager *locationManager;
	CLGeocoder *geocoder;
	CLLocation *current, *selectedRule;
	NSDate *startDate;
	
	// for custom panel
    IBOutlet MKMapView *mapView;
	NSString *address;
	NSString *coordinates;
	NSString *accuracy;
}


- (id)init {
    self = [super initWithNibNamed:@"CoreLocationRule"];
    if (!self) {
        return nil;
    }
    
	geocoder = [[CLGeocoder alloc] init];
	
	// for custom panel
	address = @"";
	coordinates = @"0.0, 0.0";
	accuracy = @"0 m";
	
    return self;
}

- (NSString *)description {
    return NSLocalizedString(@"Create rules based on your current location using OS X's Core Location framework.", @"");
}

- (void)dealloc {
	[self stop];
	[geocoder cancelGeocode];
	geocoder = nil;
}

- (void)start {
	if (running) {
		return;
    }
    
	startDate = [NSDate date];
    
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;

	[self requestLocationAuthorizationIfNeeded];
	running = YES;

	if ([self isLocationAuthorizationDeniedOrRestricted]) {
		DSLog(@"Core Location is denied or restricted; location evidence will not collect data until permission is granted in System Settings.");
		[self setDataCollected:NO];
		return;
	}

	if ([self isLocationAuthorizationGranted]) {
		[locationManager startUpdatingLocation];
		[self setDataCollected:YES];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateMap];
		});
	} else {
		// NotDetermined: wait for locationManagerDidChangeAuthorization:
		[self setDataCollected:NO];
	}
}

- (void)stop {
	if (!running) {
		return;
    }
    
    if (locationManager) {
        [locationManager stopUpdatingLocation];
        locationManager.delegate = nil;
        locationManager = nil;
    }
	current = nil;
    
	[self setDataCollected:NO];
	running = NO;
}

- (NSMutableDictionary *)readFromPanel {
	NSMutableDictionary *dict = [super readFromPanel];
	
	// store values
	dict[@"parameter"] = coordinates;
	if (!dict[@"description"]) {
		dict[@"description"] = address;
    }
	
	return dict;
}

- (void)writeToPanel:(NSDictionary *)dict usingType:(NSString *)type {
	[super writeToPanel: dict usingType: type];
	NSString *add = @"";
	
	// do we already have settings?
	if (dict[@"parameter"]) {
		selectedRule = [[CLLocation alloc] initWithText:dict[@"parameter"]];
    }
	else {
		selectedRule = [current copy];
    }
	
	// get corresponding address
	if (![CoreLocationSource geocodeLocation: selectedRule toAddress: &add]) {
		add = NSLocalizedString(@"Unknown address", @"CoreLocation");
    }
	
	// show values
	[self setValue:[selectedRule convertToText] forKey:@"coordinates"];
	[self setValue:add forKey:@"address"];
    [self updateMap];
}

- (NSString *)name {
	return @"CoreLocation";
}

- (BOOL)doesRuleMatch:(NSDictionary *)rule {
    if (current) {
        // get coordinates of rule
        CLLocation *ruleLocation = [[CLLocation alloc] initWithText:rule[@"parameter"]];
        if (ruleLocation) {
            // match if distance is smaller than accuracy
            return ([ruleLocation distanceFromLocation:current] <= current.horizontalAccuracy);
        }
    }
    return NO;
}

- (IBAction)showCoreLocation:(id)sender {
	NSString *add = nil;
	
	selectedRule = [current copy];
	if (![CoreLocationSource geocodeLocation:selectedRule toAddress:&add]) {
		add = NSLocalizedString(@"Unknown address", @"CoreLocation");
    }
	
	// show values
	[self setValue:[selectedRule convertToText] forKey:@"coordinates"];
	[self setValue:add forKey:@"address"];
    [self updateMap];
}

#pragma mark -
#pragma mark UI Validation

- (BOOL)validateAddress:(inout NSString **)newValue error:(out NSError **)outError {
	// check address
	CLLocation *loc = nil;
	BOOL result = [CoreLocationSource geocodeAddress:newValue toLocation:&loc];
	
	// if correct, set coordinates
	if (result) {
		selectedRule = loc;
		
		[self setValue:[loc convertToText] forKey:@"coordinates"];
		[self setValue:*newValue forKey:@"address"];
        [self updateMap];
	}
	
	return result;
}

- (BOOL)validateCoordinates:(inout NSString **)newValue error:(out NSError **)outError {
	// check coordinates
	CLLocation *loc = [[CLLocation alloc] initWithText:*newValue];
	if (!loc) {
        return NO;
    }
    selectedRule = loc;
    
    NSString *add = nil;
    [CoreLocationSource geocodeLocation:loc toAddress:&add];
    
    [self setValue:*newValue forKey:@"coordinates"];
    [self setValue:add forKey:@"address"];
    [self updateMap];
    
	return YES;
}

#pragma mark -
#pragma mark JavaScript stuff

- (void)updateSelectedWithLatitude:(NSNumber *)latitude andLongitude:(NSNumber *)longitude {
	selectedRule = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
    
	NSString *add = nil;
	if (![CoreLocationSource geocodeLocation:selectedRule toAddress:&add]) {
		add = NSLocalizedString(@"Unknown address", @"CoreLocation");
    }
	
	// show values
	[self setValue:[selectedRule convertToText] forKey:@"coordinates"];
	[self setValue:add forKey:@"address"];
}

//- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
//	if (running && (frame == [frame findFrameNamed:@"_top"])) {
//		[sender.windowScriptObject setValue:self forKey:@"cocoa"];
//	}
//}
//
//+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
//	if (selector == @selector(updateSelectedWithLatitude:andLongitude:)) {
//		return NO;
//	}
//	return YES;
//}
//
//+ (NSString *)webScriptNameForSelector:(SEL)sel {
//	if (sel == @selector(updateSelectedWithLatitude:andLongitude:)) {
//		return @"updateSelected";
//    }
//	return nil;
//}

#pragma mark -
#pragma mark CoreLocation callbacks

- (CLAuthorizationStatus)currentLocationAuthorizationStatus
{
    if (@available(macOS 11.0, *)) {
        return locationManager.authorizationStatus;
    }
    return [CLLocationManager authorizationStatus];
}

- (BOOL)isLocationAuthorizationDeniedOrRestricted
{
    CLAuthorizationStatus status = [self currentLocationAuthorizationStatus];
    return (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted);
}

- (BOOL)isLocationAuthorizationGranted
{
    CLAuthorizationStatus status = [self currentLocationAuthorizationStatus];
    // macOS exposes Always / Authorized; WhenInUse is not available on this SDK.
    return (status == kCLAuthorizationStatusAuthorizedAlways);
}

- (void)requestLocationAuthorizationIfNeeded
{
    CLAuthorizationStatus status = [self currentLocationAuthorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        [locationManager requestWhenInUseAuthorization];
    }
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager
{
    (void)manager;
    if (!running || locationManager == nil) {
        return;
    }

    if ([self isLocationAuthorizationGranted]) {
        [locationManager startUpdatingLocation];
        [self setDataCollected:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateMap];
        });
    } else if ([self isLocationAuthorizationDeniedOrRestricted]) {
        DSLog(@"Core Location permission denied; stopping location updates.");
        [locationManager stopUpdatingLocation];
        current = nil;
        [self setDataCollected:NO];
    }
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
	
	// Ignore invalid updates
	if (![self isValidLocation:newLocation withOldLocation:oldLocation]) {
		return;
    }
	
	// location
	current = [newLocation copy];
	CLLocationAccuracy acc = current.horizontalAccuracy;
#ifdef DEBUG_MODE
	CLLocationDegrees lat = current.coordinate.latitude;
	CLLocationDegrees lon = current.coordinate.longitude;
	DSLog(@"New location: (%f, %f) with accuracy %f", lat, lon, acc);
#endif
	
	// store
	[self setValue:[NSString stringWithFormat:@"%d m", (int) acc] forKey:@"accuracy"];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	DSLog(@"Location manager failed with error: %@", [error localizedDescription]);
	
	switch (error.code) {
		case kCLErrorDenied:
			DSLog(@"Core Location denied!");
			[self stop];
			break;
            
		default:
			break;
	}
}

#pragma mark -
#pragma mark Helper functions

- (void)updateMap {
    if (!running) {
        return;
    }
    
    static const void *mainQueueKey = &mainQueueKey;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_set_specific(dispatch_get_main_queue(), mainQueueKey, (void *)1, NULL);
    });
    
    // Check if we're on the main queue
    if (dispatch_get_specific(mainQueueKey) == NULL) {
        // We're not on the main queue, so dispatch to main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateMap];
        });
        return;
    }
    
	// Get coordinates and replace placeholders with these
    NSString *htmlPath = [NSBundle.mainBundle pathForResource:@"CoreLocationMap" ofType:@"html"];
	NSString *htmlTemplate = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:NULL];
    
#ifdef DEBUG_MODE
    NSLog(@"htmlTemplate %@", htmlTemplate);
#endif
	NSString *htmlString = [NSString stringWithFormat:htmlTemplate,
							(current ? current.coordinate.latitude : 0.0),
							(current ? current.coordinate.longitude : 0.0),
							(selectedRule ? selectedRule.coordinate.latitude : 0.0),
							(selectedRule ? selectedRule.coordinate.longitude : 0.0),
							(current ? current.horizontalAccuracy : 0.0)];
#ifdef DEBUG_MODE
	NSLog(@"htmlString is %@", htmlString);
#endif
	// Load the HTML in the WebView
//	[webView.mainFrame loadHTMLString:htmlString baseURL:nil];
}


+ (BOOL)geocodeAddress:(NSString **)address toLocation:(CLLocation **)location {
	if (!address || !*address || [*address length] == 0) {
		return NO;
	}
	
	__block BOOL success = NO;
	__block CLLocation *resultLocation = nil;
	__block NSString *resultAddress = nil;
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	CLGeocoder *localGeocoder = [[CLGeocoder alloc] init];
	
	[localGeocoder geocodeAddressString:*address completionHandler:^(NSArray<CLPlacemark *> *placemarks, NSError *error) {
		if (error) {
			DSLog(@"Geocode address failed: %@", [error localizedDescription]);
		} else if (placemarks && [placemarks count] > 0) {
			CLPlacemark *placemark = placemarks[0];
			resultLocation = placemark.location;
			
			// Format the address from placemark components
			NSMutableArray *addressParts = [NSMutableArray array];
			if (placemark.subThoroughfare) [addressParts addObject:placemark.subThoroughfare];
			if (placemark.thoroughfare) [addressParts addObject:placemark.thoroughfare];
			if (placemark.locality) [addressParts addObject:placemark.locality];
			if (placemark.administrativeArea) [addressParts addObject:placemark.administrativeArea];
			if (placemark.postalCode) [addressParts addObject:placemark.postalCode];
			if (placemark.country) [addressParts addObject:placemark.country];
			
			if ([addressParts count] > 0) {
				resultAddress = [addressParts componentsJoinedByString:@", "];
			}
			success = YES;
		}
		dispatch_semaphore_signal(semaphore);
	}];
	
	// Wait up to 10 seconds for geocoding to complete
	dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC);
	long result = dispatch_semaphore_wait(semaphore, timeout);
	
	if (result != 0) {
		// Timeout occurred
		DSLog(@"Geocode address timed out");
		[localGeocoder cancelGeocode];
		return NO;
	}
	
	if (success && resultLocation) {
		*location = resultLocation;
		if (resultAddress) {
			*address = resultAddress;
		}
	}
	
	return success;
}

+ (BOOL)geocodeLocation:(CLLocation *)location toAddress:(NSString **)address {
	if (!location) {
		return NO;
	}
	
	__block BOOL success = NO;
	__block NSString *resultAddress = nil;
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	CLGeocoder *localGeocoder = [[CLGeocoder alloc] init];
	
	[localGeocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> *placemarks, NSError *error) {
		if (error) {
			DSLog(@"Reverse geocode failed: %@", [error localizedDescription]);
		} else if (placemarks && [placemarks count] > 0) {
			CLPlacemark *placemark = placemarks[0];
			
			// Format the address from placemark components
			NSMutableArray *addressParts = [NSMutableArray array];
			if (placemark.subThoroughfare) [addressParts addObject:placemark.subThoroughfare];
			if (placemark.thoroughfare) [addressParts addObject:placemark.thoroughfare];
			if (placemark.locality) [addressParts addObject:placemark.locality];
			if (placemark.administrativeArea) [addressParts addObject:placemark.administrativeArea];
			if (placemark.postalCode) [addressParts addObject:placemark.postalCode];
			if (placemark.country) [addressParts addObject:placemark.country];
			
			if ([addressParts count] > 0) {
				resultAddress = [addressParts componentsJoinedByString:@", "];
				success = YES;
			}
		}
		dispatch_semaphore_signal(semaphore);
	}];
	
	// Wait up to 10 seconds for geocoding to complete
	dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC);
	long result = dispatch_semaphore_wait(semaphore, timeout);
	
	if (result != 0) {
		// Timeout occurred
		DSLog(@"Reverse geocode timed out");
		[localGeocoder cancelGeocode];
		return NO;
	}
	
	if (success && resultAddress) {
		*address = resultAddress;
	}
	
	return success;
}

- (BOOL)isValidLocation:(CLLocation *)newLocation withOldLocation:(CLLocation *)oldLocation {
	// Filter out nil locations
	if (!newLocation) {
		return NO;
    }
	// Filter out points by invalid accuracy
	if (newLocation.horizontalAccuracy < 0) {
		return NO;
    }
	// Filter out points that are out of order
	NSTimeInterval secondsSinceLastPoint = [newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp];
	if (secondsSinceLastPoint < 0) {
		return NO;
    }
	// Filter out points created before the manager was initialized
	NSTimeInterval secondsSinceManagerStarted = [newLocation.timestamp timeIntervalSinceDate:startDate];
	if (secondsSinceManagerStarted < 0) {
		return NO;
    }
	// The newLocation is good to use
	return YES;
}

- (void)wakeFromSleep:(id)arg {
    if (goingToSleep) {
        goingToSleep = NO;
        if (startAfterSleep && ![self isRunning]) {
            startAfterSleep = NO;
            running = YES;
            
            DSLog(@"Starting %@ after sleep.", [self class]);
            [locationManager startUpdatingLocation];
        }
    }
}

- (void)goingToSleep:(id)arg {
    if (!goingToSleep) {
        goingToSleep = YES;
        if ([self isRunning]) {
            startAfterSleep = YES;
            running = NO;
            
            DSLog(@"Stopping %@ for sleep.", [self class]);
            [locationManager stopUpdatingLocation];
        }
    }
}

- (NSString *)friendlyName {
    return NSLocalizedString(@"Current Location", @"");
}

@end
