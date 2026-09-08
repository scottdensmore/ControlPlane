//
//  CPHelperClientGate.m
//  com.scottdensmore.CPHelperTool
//
//  Accept/reject decision for privileged helper XPC clients (#166).
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "CPHelperClientGate.h"

#import <Security/Security.h>

NSString * const kCPHelperAuthorizedClientIdentifier = @"com.scottdensmore.CPXPCService";
NSString * const kCPHelperAuthorizedAppIdentifier = @"com.scottdensmore.ControlPlane";
NSString * const kCPHelperAuthorizedClientTeamIdentifier = @"27ZDER873F";

@implementation CPHelperClientGate

+ (BOOL)shouldAcceptClientWithIdentifier:(NSString *)identifier
                          teamIdentifier:(NSString *)teamIdentifier
                                isSigned:(BOOL)isSigned
{
    if (!isSigned) {
        return NO;
    }
    if (identifier.length == 0 || teamIdentifier.length == 0) {
        return NO;
    }
    if (![teamIdentifier isEqualToString:kCPHelperAuthorizedClientTeamIdentifier]) {
        return NO;
    }
    if (![identifier isEqualToString:kCPHelperAuthorizedClientIdentifier]
        && ![identifier isEqualToString:kCPHelperAuthorizedAppIdentifier]) {
        return NO;
    }
    return YES;
}

+ (NSString *)codeSigningRequirementTail
{
    // Same clauses as SMAuthorizedClients: apple generic anchor, leaf subject.OU,
    // Apple Development (1.2.840.113635.100.6.2.1) or Developer ID (…100.6.2.6).
    return [NSString stringWithFormat:
            @"anchor apple generic and certificate leaf[subject.OU] = \"%@\" and (certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */)",
            kCPHelperAuthorizedClientTeamIdentifier];
}

+ (NSString *)smAuthorizedClientsRequirementForIdentifier:(NSString *)identifier
{
    return [NSString stringWithFormat:@"identifier \"%@\" and %@",
            identifier, [self codeSigningRequirementTail]];
}

+ (NSString *)listenerCodeSigningRequirement
{
    return [NSString stringWithFormat:@"(identifier \"%@\" or identifier \"%@\") and %@",
            kCPHelperAuthorizedClientIdentifier,
            kCPHelperAuthorizedAppIdentifier,
            [self codeSigningRequirementTail]];
}

+ (BOOL)isValidCodeSigningRequirement:(NSString *)requirement
{
    if (requirement.length == 0) {
        return NO;
    }
    SecRequirementRef requirementRef = NULL;
    OSStatus status = SecRequirementCreateWithString((__bridge CFStringRef)requirement,
                                                      kSecCSDefaultFlags,
                                                      &requirementRef);
    if (requirementRef != NULL) {
        CFRelease(requirementRef);
    }
    return status == errSecSuccess;
}

@end
