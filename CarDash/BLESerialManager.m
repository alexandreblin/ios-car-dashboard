//
//  BLESerialManager.m
//  HMSoft
//
//  Created by HMSofts on 7/13/12.
//  Copyright (c) 2012 jnhuamao.cn. All rights reserved.
//

#import "BLESerialManager.h"

@interface BLESerialManager ()

@property (nonatomic, strong) NSMutableDictionary *managedDevices;
@property (nonatomic, strong) NSTimer *timeoutTimer;

@end

@implementation BLESerialManager


/*
 * (id)init
 * enable CoreBluetooth CentralManager and set the delegate for SerialGATT
 *
 */
- (id)init
{
    self = [super init];
    
    if (self) {
        self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.managedDevices = [NSMutableDictionary dictionary];
    }
    
    return self;
}

/*
 * - (BOOL)startScanningWithTimeout:(NSTimeInterval)timeout
 *
 */
- (BOOL)startScanningWithTimeout:(NSTimeInterval)timeout
{
    if (self.manager.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth is not correctly initialized !");
        return NO;
    }
    
    [self.timeoutTimer invalidate];
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(stopScanning) userInfo:nil repeats:NO];
    
    [self.manager scanForPeripheralsWithServices:nil options:0];
    
    return YES;
}

/*
 * scanTimer
 * when findHMSoftPeripherals is timeout, this function will be called
 *
 */
- (void)stopScanning
{
    [self.manager stopScan];
    [self.delegate scanEnded];
}

/*
 *  @method printPeripheralInfo:
 *
 *  @param peripheral Peripheral to print info of 
 *
 *  @discussion printPeripheralInfo prints detailed info about peripheral 
 *
 */
- (void)printPeripheralInfo:(CBPeripheral*)peripheral {
    CFStringRef s = CFUUIDCreateString(NULL, (__bridge CFUUIDRef )peripheral.identifier);
    printf("------------------------------------\r\n");
    printf("Peripheral Info :\r\n");
    printf("UUID : %s\r\n",CFStringGetCStringPtr(s, 0));
    //printf("RSSI : %d\r\n",[peripheral.RSSI intValue]);
    printf("Name : %s\r\n",[peripheral.name cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    printf("isConnected : %d\r\n",peripheral.state == CBPeripheralStateConnected);
    printf("-------------------------------------\r\n");
    
}

/*
 * connect
 * connect to a given peripheral
 *
 */
- (void)connectToDevice:(BLESerialDevice *)serialDevice
{
    [self.manager connectPeripheral:serialDevice.peripheral options:nil];
}

/*
 * disconnect
 * disconnect to a given peripheral
 *
 */
- (void)disconnectFromDevice:(BLESerialDevice *)serialDevice
{
    [self.manager cancelPeripheralConnection:serialDevice.peripheral];
}


#pragma mark - CBCentralManager Delegates

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self.delegate centralManagerStateUpdated:central.state];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    BLESerialDevice *serialDevice = self.managedDevices[peripheral];
    if (!serialDevice) {
        serialDevice = [[BLESerialDevice alloc] initWithPeripheral:peripheral andManager:self];
        self.managedDevices[peripheral] = serialDevice;
    }
    
    [self.delegate deviceFound:serialDevice];
    
    /*if (!self.peripherals) {
        self.peripherals = [[NSMutableArray alloc] initWithObjects:peripheral, nil];
        for (int i = 0; i < [self.peripherals count]; i++) {
            BLESerialPeripheral *serialPeripheral = self.managedPeripherals[peripheral];
            if (!serialPeripheral) {
                serialPeripheral = [[BLESerialPeripheral alloc] initWithPeripheral:peripheral];
            }
            
            [self.delegate peripheralFound:serialPeripheral];
        }
    }
    
    {
        if((__bridge CFUUIDRef )peripheral.identifier == NULL) return;
        //if(peripheral.name == NULL) return;
        //if(peripheral.name == nil) return;
        if(peripheral.name.length < 1) return;
        // Add the new peripheral to the peripherals array
        for (int i = 0; i < [self.peripherals count]; i++) {
            CBPeripheral *p = self.peripherals[i];
            if((__bridge CFUUIDRef )p.identifier == NULL) continue;
            CFUUIDBytes b1 = CFUUIDGetUUIDBytes((__bridge CFUUIDRef )p.identifier);
            CFUUIDBytes b2 = CFUUIDGetUUIDBytes((__bridge CFUUIDRef )peripheral.identifier);
            if (memcmp(&b1, &b2, 16) == 0) {
                // these are the same, and replace the old peripheral information
                self.peripherals[i] = peripheral;
                printf("Duplicated peripheral is found...\n");
                //[delegate peripheralFound: peripheral];
                return;
            }
        }
        printf("New peripheral is found...\n");
        [self.peripherals addObject:peripheral];
        [self.delegate peripheralFound:peripheral];
        return;
    }
    printf("%s\n", __FUNCTION__);*/
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    BLESerialDevice *serialDevice = self.managedDevices[peripheral];
    serialDevice.connected = YES;
    
    //[self notify:peripheral on:YES];
    
    //[self printPeripheralInfo:peripheral];
    
    //printf("connected to the active peripheral\n");
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    //printf("disconnected to the active peripheral\n");
    [self.managedDevices[peripheral] setConnected:NO];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"failed to connect to peripheral %@: %@\n", [peripheral name], [error localizedDescription]);
}

@end
