//
//  BLESerialManager.h
//  HMSoft
//
//  Created by HMSofts on 7/13/12.
//  Copyright (c) 2012 jnhuamao.cn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLESerialDevice.h"

#define SERVICE_UUID     0xFFE0
#define CHAR_UUID        0xFFE1

@class BLESerialDevice;

@protocol BLESerialManagerDelegate

@optional
- (void)centralManagerStateUpdated:(CBCentralManagerState)state;
- (void)deviceFound:(BLESerialDevice *)serialDevice;
- (void)scanEnded;

@end

@interface BLESerialManager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, assign) id <BLESerialManagerDelegate> delegate;
@property (strong, nonatomic) CBCentralManager *manager;

- (BOOL)startScanningWithTimeout:(NSTimeInterval)timeout;
- (void)stopScanning;

- (void)connectToDevice:(BLESerialDevice *)serialDevice;
- (void)disconnectFromDevice:(BLESerialDevice *)serialDevice;

@end
