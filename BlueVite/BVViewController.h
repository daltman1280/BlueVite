//
//  BVViewController.h
//  BlueVite
//
//  Created by Don Altman on 9/2/14.
//  Copyright (c) 2014 don.altman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BVViewController : UIViewController <CBPeripheralManagerDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *messageTextField;				// populate when beacon event is detected
@property (weak, nonatomic) IBOutlet UIButton *startStopAdvertisingButton;

@property (strong) NSDictionary*		beaconPeripheralData;
@property (strong) CBPeripheralManager*	peripheralManager;
@property (strong) CLLocationManager*	locationManager;
@property (strong) CLBeaconRegion*		beaconRegion;

@end
