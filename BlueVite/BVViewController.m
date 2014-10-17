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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.locationManager = [[CLLocationManager alloc] init];			// location manager data member, should be created as a strong reference
	self.locationManager.delegate = self;
	CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
	//	if bluetooth is not available, prompt user to enable it
	if (status != kCLAuthorizationStatusAuthorized && status != kCLAuthorizationStatusAuthorizedAlways && status != kCLAuthorizationStatusAuthorizedWhenInUse) {
		
	}
	//	Create a peripheral manager in order to start advertising
	NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uuidString];
	self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:@"test1"];
	// create a dictionary of advertising data
	self.beaconPeripheralData = [self.beaconRegion peripheralDataWithMeasuredPower:nil];
	// create a beacon region to monitor
	NSLog(@"monitorButton, isMonitoringAvailable = %d, authorizationStatus = %d, locationServicesEnabled = %d", [CLLocationManager isMonitoringAvailableForClass:[CLRegion class]], [CLLocationManager authorizationStatus], [CLLocationManager locationServicesEnabled]);
	NSLog(@"monitorButton, backgroundRefreshStatus = %d", [UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusAvailable);
	NSLog(@"name = %@", [UIDevice currentDevice].name);
	NSLog(@"identifier = %@", [UIDevice currentDevice].identifierForVendor.UUIDString);
	NSLog(@"advertising identifier = %@", [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//	user selected start/stop advertising button

- (IBAction)createAndAdvertiseButton:(id)sender {
	if (!self.peripheralManager) {																	// first time, create peripheral manager. Must start advertising from delegate
		self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
		self.peripheralManager.delegate = self;
	} else																							// not first time, peripheral manager already created
		[self peripheralManagerDidUpdateState:self.peripheralManager];								// directly call the delegate
}

//	start monitoring for bluetooth beacon events

- (IBAction)monitorButton:(id)sender {
	[self.locationManager startMonitoringForRegion:self.beaconRegion];								// start monitoring beacon
}

- (IBAction)stopMonitorButton:(id)sender {
	[self.locationManager stopMonitoringForRegion:self.beaconRegion];								// stop monitoring beacon
}

#pragma mark CBPeripheralManagerDelegate

//	respond when state changes, if bluetooth power is on, start/stop advertising

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
	}
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
									   error:(NSError *)error
{
	NSLog(@"peripheralManagerDidStartAdvertising, error = %@", [error localizedDescription]);
}

#pragma mark CLLocationManagerDelegate

//	new location data is available

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	NSLog(@"didUpdateLocations");
}

//	user entered a region, or beacon started advertising

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
	NSLog(@"didEnterRegion");
	self.messageTextField.text = @"didEnterRegion";
	// if application is in background state, issue notification so user can bring it to foreground
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
		UILocalNotification *notification = [[UILocalNotification alloc] init];
		notification.alertBody = @"Hi there!";
		[[UIApplication sharedApplication] presentLocalNotificationNow:notification];		// present a notification, to bring application to foreground
	}
}

//	user exited a region, or beacon stopped advertising

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
	NSLog(@"didExitRegion");
	self.messageTextField.text = @"didExitRegion";
}

//	new region is being monitored

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
	NSLog(@"didStartMonitoringForRegion");
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"didFailWithError, error = %@", [error localizedDescription]);
}

@end
