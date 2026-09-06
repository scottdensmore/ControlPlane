//
//  ConnectBluetoothDeviceAction.m
//  ControlPlane
//
//  Created by Chris Lundie on 1/May/2014.
//  Updated for #117: do not cascade through gated Toggle Bluetooth power APIs.
//

#import "ConnectBluetoothDeviceAction.h"
#import <IOBluetooth/IOBluetooth.h>

@interface ConnectBluetoothDeviceAction ()

@property (copy) NSString *deviceAddressString;

@end

@implementation ConnectBluetoothDeviceAction

- (instancetype)initWithOption:(NSString *)option
{
  self = [super init];
  if (self) {
    self.deviceAddressString = option;
  }
  return self;
}

- (instancetype)init
{
  return [self initWithOption:@""];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
  return [self initWithOption:dict[@"parameter"]];
}

- (void)dealloc
{
  self.deviceAddressString = nil;
  
}

- (NSMutableDictionary *)dictionary
{
  NSMutableDictionary *dict = [super dictionary];
  dict[@"parameter"] = [self.deviceAddressString copy];
  return dict;
}

- (NSString *)description
{
  NSString *format = NSLocalizedString(
    @"Connecting to Bluetooth device '%@'.", @"");
  return [NSString stringWithFormat:format, self.deviceAddressString];
}

+ (BOOL)bluetoothRadioPowered
{
  IOBluetoothHostController *controller = [IOBluetoothHostController defaultController];
  if (!controller) {
    return NO;
  }
  return [controller powerState] == kBluetoothHCIPowerStateON;
}

- (BOOL)execute:(NSString **)errorString
{
  if (![ConnectBluetoothDeviceAction bluetoothRadioPowered]) {
    if (errorString) {
      *errorString = NSLocalizedString(
        @"Bluetooth is off. Turn it on in Control Center or System Settings → Bluetooth "
        @"(or run a Shortcut that enables Bluetooth), then try Connect Bluetooth Device again. "
        @"ControlPlane no longer toggles Bluetooth power via private APIs.",
        @"Error when ConnectBluetoothDeviceAction runs with radio off");
    }
    return NO;
  }

  NSString *address = [self.deviceAddressString stringByTrimmingCharactersInSet:
    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (address.length == 0) {
    if (errorString) {
      *errorString = NSLocalizedString(@"Cannot connect: Bluetooth device address is empty.", @"");
    }
    return NO;
  }

  IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:address];
  IOReturn ioReturn = [device openConnection];
  if (!device || (ioReturn != kIOReturnSuccess)) {
    if (errorString) {
      *errorString = [NSString stringWithFormat:
        NSLocalizedString(@"Failed to connect to Bluetooth device '%@'.", @""), address];
    }
    return NO;
  }
  return YES;
}

+ (NSString *)helpText
{
  return NSLocalizedString(
    @"The parameter for ConnectBluetoothDevice actions is the address of the"
    @" device. Bluetooth must already be powered on (Control Center / System Settings"
    @" or a Shortcut). ControlPlane does not turn Bluetooth on via private APIs.",
    @"");
}

+ (NSString *)creationHelpText
{
  return NSLocalizedString(@"Connecting to Bluetooth device", @"");
}

+ (NSArray *)limitedOptions
{
  NSArray *devices = [IOBluetoothDevice pairedDevices];
  NSMutableArray *options = [NSMutableArray array];
  for (IOBluetoothDevice *device in devices) {
    NSString *deviceName = device.nameOrAddress;
    NSString *deviceAddress = device.addressString;
    if (!deviceAddress) {
      continue;
    }
    [options addObject:@{
      @"option": deviceAddress,
      @"description": deviceName ?: deviceAddress
    }];
  }
  return options;
}

+ (NSString *)friendlyName
{
  return NSLocalizedString(@"Connect Bluetooth Device", @"");
}

+ (NSString *)menuCategory
{
  return NSLocalizedString(@"Bluetooth", @"");
}

@end
