//
//  CPContextAppIntentBridge.h
//  ControlPlane
//
//  Swift App Intents call this. It lists Force Context menu names and switches
//  through CPController, without opening a window.
//

#import <Foundation/Foundation.h>

@interface CPContextAppIntentBridge : NSObject

+ (NSArray<NSString *> *)orderedContextTokens;

+ (BOOL)forceSwitchToContextNamed:(NSString *)name error:(NSError **)error;

@end
