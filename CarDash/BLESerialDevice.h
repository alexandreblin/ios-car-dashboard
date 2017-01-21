//
//  BLESerialDevice.h
//  SerialBLE
//
//  Created by Alexandre on 03/12/2013.
//  Copyright (c) 2013 Alexandre Blin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLESerialManager.h"

@class BLESerialDevice, BLESerialManager;

@protocol BLESerialDeviceDelegate

- (void)serialDevice:(BLESerialDevice *)serialDevice didReceiveData:(NSData *)data forUUID:(NSString *)UUID;
- (void)serialDeviceDidConnect:(BLESerialDevice *)serialDevice;
- (void)serialDeviceDidDisconnect:(BLESerialDevice *)serialDevice;

@end

@interface BLESerialDevice : NSObject

@property (nonatomic, weak) id<BLESerialDeviceDelegate> delegate;

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, assign) BOOL connected;

- (id)initWithPeripheral:(CBPeripheral *)peripheral andManager:(BLESerialManager *)manager;
- (void)connect;
- (void)writeData:(NSData *)data;

@end
