//
//  BVViewController.h
//  BlueVite
//
//  Created by Don Altman on 9/2/14.
//  Copyright (c) 2014 don.altman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BVViewController : UIViewController <CBPeripheralManagerDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *messageTextField;				// populate when beacon event is detected
@property (weak, nonatomic) IBOutlet UIButton *startStopAdvertisingButton;
@property (weak, nonatomic) IBOutlet UILabel *majorAdvertised;
@property (weak, nonatomic) IBOutlet UILabel *minorAdvertised;
@property (weak, nonatomic) IBOutlet UILabel *majorMonitored;
@property (weak, nonatomic) IBOutlet UILabel *minorMonitored;

@property (strong) NSDictionary*		beaconPeripheralData;					// identifying information for the beacon
@property (strong) CBPeripheralManager*	peripheralManager;
@property (strong) CLLocationManager*	locationManager;
@property (strong) CLBeaconRegion*		beaconRegionForMonitoring;				// used for monitoring
@property (strong) CLBeaconRegion*		beaconRegionForAdvertising;				// used for advertising (independent of monitoring)

@end
