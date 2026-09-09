//
//  CPHelperClientGate.h
//  com.scottdensmore.CPHelperTool
//
//  Accept/reject decision for privileged helper XPC clients (#166).
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// XPC service that brokers the first connection to the helper.
FOUNDATION_EXPORT NSString * const kCPHelperAuthorizedClientIdentifier;

/// App that sends privileged commands on the helper endpoint after
/// connectWithEndpointReply:. Same listener as the XPC service hop.
/// Identifier matches Info.plist CFBundleURLName and PRODUCT_NAME ControlPlane
/// (`com.scottdensmore.${PRODUCT_NAME:rfc1034identifier}`).
FOUNDATION_EXPORT NSString * const kCPHelperAuthorizedAppIdentifier;

/// Team ID (certificate leaf subject.OU) required of either client.
FOUNDATION_EXPORT NSString * const kCPHelperAuthorizedClientTeamIdentifier;

@interface CPHelperClientGate : NSObject

/// YES only for a signed client whose team matches and whose identifier is
/// the XPC service or the ControlPlane app. Attributes are injected so tests
/// do not need a live root helper.
+ (BOOL)shouldAcceptClientWithIdentifier:(nullable NSString *)identifier
                          teamIdentifier:(nullable NSString *)teamIdentifier
                                isSigned:(BOOL)isSigned;

/// Single-identifier requirement (identifier, anchor apple generic, leaf OU,
/// both intermediates). Kept so listener tests can compare clause tails.
+ (NSString *)smAuthorizedClientsRequirementForIdentifier:(NSString *)identifier;

/// Listener requirement: same anchor, leaf OU, and intermediates, but either
/// allowed identifier so the app endpoint hop is not refused. This is the
/// client gate. Apply with -[NSXPCListener setConnectionCodeSigningRequirement:]
/// before the listener resumes.
+ (NSString *)listenerCodeSigningRequirement;

/// YES when Security accepts the requirement string (SecRequirementCreateWithString).
+ (BOOL)isValidCodeSigningRequirement:(nullable NSString *)requirement;

@end

NS_ASSUME_NONNULL_END
