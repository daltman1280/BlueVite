//
//  BVViewController.m
//  BlueVite
//
//  Created by Don Altman on 9/2/14.
//  Copyright (c) 2014 don.altman. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <AdSupport/ASIdentifierManager.h>
#import "BVViewController.h"

//	distinguishes beacons that belong to this application from other applications

static NSString *uuidString = @"D86BB080-18B2-4D40-916B-72DEF0F574AC";

@interface BVViewController ()

@end

@implementation BVViewController

- (void)viewDidAppear:(BOOL)animated
{
	UInt16 majorValue = 1234;																											// identifies the source of a beacon
	UInt16 minorValue = 5678;																											// identifies the source of a beacon
	SecRandomCopyBytes(kSecRandomDefault, 2, (uint8_t *) &majorValue);																	// assign a random value
	SecRandomCopyBytes(kSecRandomDefault, 2, (uint8_t *) &minorValue);																	// assign a random value
	self.majorAdvertised.text = [NSString stringWithFormat:@"%d", majorValue];
	self.minorAdvertised.text = [NSString stringWithFormat:@"%d", minorValue];
	NSString *monitoredBeaconIdentifier = @"com.homebodyapps.testBeaconMonitored";														// used as the handle to the beacon
	NSString *advertisedBeaconIdentifier = @"com.homebodyapps.testBeaconAdvertised";													// used as the handle to the beacon
	
	self.locationManager = [[CLLocationManager alloc] init];			// location manager data member, should be created as a strong reference
	self.locationManager.delegate = self;
	
	// set up services
	
	bool enabled = [CLLocationManager locationServicesEnabled];
	if (!enabled) {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
																	   message:@"Please enable location services."
																preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[alert addAction:defaultAction];
		[self presentViewController:alert animated:YES completion:nil];
		return;
	}
	CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
	if (status == kCLAuthorizationStatusDenied) {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Location Services Denied"
																	   message:@"Please allow location access for BlueVite."
																preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[alert addAction:defaultAction];
		[self presentViewController:alert animated:YES completion:nil];
		return;
	}
	//	if bluetooth is not available, prompt user to enable it
	if (status != kCLAuthorizationStatusAuthorizedAlways && status != kCLAuthorizationStatusAuthorizedWhenInUse) {
		[self.locationManager requestAlwaysAuthorization];
	}
	
	// create a beacon region to monitor (don't specify major, minor values
	
	NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uuidString];
	self.beaconRegionForMonitoring = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:monitoredBeaconIdentifier];		// monitor all major, minor values
	self.beaconRegionForMonitoring.notifyOnExit = YES;																				// default is YES
	[self stopMonitorButton:self];
	
	// create a beacon region to advertise, with specific major, minor values
	
	self.beaconRegionForAdvertising = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:majorValue minor:minorValue identifier:advertisedBeaconIdentifier];
	// create a dictionary of advertising data
	self.beaconPeripheralData = [self.beaconRegionForAdvertising peripheralDataWithMeasuredPower:nil];								// nil for default
	
	// logging
	
	NSLog(@"monitorButton, isMonitoringAvailable = %d, authorizationStatus = %d, locationServicesEnabled = %d", [CLLocationManager isMonitoringAvailableForClass:[CLRegion class]], [CLLocationManager authorizationStatus], [CLLocationManager locationServicesEnabled]);
	NSLog(@"monitorButton, backgroundRefreshStatus = %d", [UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusAvailable);
	NSLog(@"name = %@", [UIDevice currentDevice].name);
	// this is shared by all apps for a given vendor. Unfortunately, if user removes all vendor apps, it goes away
	NSLog(@"identifier = %@", [UIDevice currentDevice].identifierForVendor.UUIDString);
	// supposed to be stable per device
	NSLog(@"advertising identifier = %@", [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString);
		NSLog(@"monitored regions = %@", self.locationManager.monitoredRegions);
}

#pragma mark control event handling

//	start/stop monitoring for Bluetooth beacon events, for testing

- (IBAction)startMonitorButton:(id)sender {
	if (self.locationManager.monitoredRegions == nil || self.locationManager.monitoredRegions.count == 0) {
		[self.locationManager startMonitoringForRegion:self.beaconRegionForMonitoring];								// start monitoring beacon
		[self.locationManager startRangingBeaconsInRegion:self.beaconRegionForMonitoring];
	}
	NSLog(@"startMonitorButton, monitored regions = %@", self.locationManager.monitoredRegions);
}

- (IBAction)stopMonitorButton:(id)sender {
	[self.locationManager stopMonitoringForRegion:self.beaconRegionForMonitoring];									// stop monitoring beacon
	[self.locationManager stopRangingBeaconsInRegion:self.beaconRegionForMonitoring];
	NSLog(@"stopMonitorButton, monitored regions = %@", self.locationManager.monitoredRegions);
}

//	user selected start/stop advertising button

- (IBAction)createAndAdvertiseButton:(id)sender {
	//	Create a peripheral manager in order to start advertising
	if (!self.peripheralManager) {																	// first time, create peripheral manager. Must start advertising from delegate
		// re-use the uuidString for peripheral manager ID
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], CBPeripheralManagerOptionShowPowerAlertKey, uuidString, CBPeripheralManagerOptionRestoreIdentifierKey, nil];
		self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:options];
	} else {																						// not first time, peripheral manager already created
		[self peripheralManagerDidUpdateState:self.peripheralManager];								// directly call the delegate
	}
}

#pragma mark CBPeripheralManagerDelegate (peripheral device)

//	respond when state changes, if Bluetooth power is on, start/stop advertising

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
	NSLog(@"peripheralManagerDidUpdateState");
	if (peripheral.state == CBPeripheralManagerStatePoweredOn) {									// toggle advertising, depending on current state
		if (!peripheral.isAdvertising) {
			[peripheral startAdvertising:self.beaconPeripheralData];
			[self.startStopAdvertisingButton setTitle:@"Stop advertising" forState:UIControlStateNormal];
		} else {
			[peripheral stopAdvertising];
			[self.startStopAdvertisingButton setTitle:@"Start advertising" forState:UIControlStateNormal];
		}
	} else {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
																	   message:@"Please enable Bluetooth."
																preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[alert addAction:defaultAction];
		[self presentViewController:alert animated:YES completion:nil];
		return;
	}
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
									   error:(NSError *)error
{
	NSLog(@"peripheralManagerDidStartAdvertising, error = %@", [error localizedDescription]);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict
{
	NSLog(@"willRestoreState, dict = %@", dict);
}

#pragma mark CLLocationManagerDelegate (central device)

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
	if (beacons.count > 0) {
		NSLog(@"didRangeBeacons, beacons = %@", beacons);
		self.majorMonitored.text = [NSString stringWithFormat:@"%d", ((CLBeacon *)beacons[0]).major.intValue];
		self.minorMonitored.text = [NSString stringWithFormat:@"%d", ((CLBeacon *)beacons[0]).minor.intValue];
	}
}

//	new location data is available

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	NSLog(@"didUpdateLocations");
}

//	user entered a region, or beacon started advertising

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLBeaconRegion *)region
{
	NSLog(@"didEnterRegion");
	self.messageTextField.text = @"didEnterRegion";
	// if application is in background state, issue notification so user can bring it to foreground
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
		UILocalNotification *notification = [[UILocalNotification alloc] init];
		notification.alertBody = @"BlueVite received didEnterRegion notification!";
		[[UIApplication sharedApplication] presentLocalNotificationNow:notification];		// present a notification, to bring application to foreground
	}
}

//	user exited a region, or beacon stopped advertising

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
	NSLog(@"didExitRegion");
	self.messageTextField.text = @"didExitRegion";
	self.majorMonitored.text = @"";
	self.minorMonitored.text = @"";
}

//	new region is being monitored

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
	NSLog(@"didStartMonitoringForRegion, monitored regions: %@", self.locationManager.monitoredRegions);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"didFailWithError, error = %@", [error localizedDescription]);
}

#pragma mark CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
	NSLog(@"didDiscoverPeripheral");
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	NSLog(@"centralManagerDidUpdateState, central = %@", central);
}

@end
