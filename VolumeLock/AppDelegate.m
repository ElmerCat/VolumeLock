//
//  AppDelegate.m
//  VolumeControlLock
//
//  Created by Elmer on 2/8/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

-(void)awakeFromNib{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.statusMenu];
    [self.statusItem setTitle:@"Volume-Unlocked"];
    [self.statusItem setHighlightMode:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    OSStatus osStatus;
    osStatus = AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment,
                                    kAuthorizationFlagDefaults, &authorizationRef);
    
    AuthorizationRightSet(NULL, "org.elmercat.volume-lock.edit",
                          CFSTR(kAuthorizationRuleIsAdmin), CFSTR("Authorize changing the Volume"), NULL, NULL);
    
    
    AudioObjectPropertyAddress devicePropertyAddress = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    AudioDeviceID deviceID;
    UInt32 dataSize = sizeof(deviceID);
    OSStatus result = AudioObjectGetPropertyData(kAudioObjectSystemObject, &devicePropertyAddress, 0, NULL, &dataSize, &deviceID);
    
    if(kAudioHardwareNoError != result) {
        // Handle the error
    }
    
    // Some devices (but not many) support a master channel
    AudioObjectPropertyAddress volumePropertyAddress = {
        kAudioDevicePropertyVolumeScalar,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster
    };
    
    if(AudioObjectHasProperty(deviceID, &volumePropertyAddress)) {
        OSStatus result = AudioObjectAddPropertyListener(deviceID, &volumePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
        if(kAudioHardwareNoError != result) {
            // Handle the error
            
            
        }
        Float32 volume = 0;
        UInt32 dataSize = sizeof(volume);
        result = AudioObjectGetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, &dataSize, &volume);
        
        if(kAudioHardwareNoError != result) {
            // Handle the error
        }
        self.lockedVolume = volume;
        
        
    }
    else {
        // Typically the L and R channels are 1 and 2 respectively, but could be different
        volumePropertyAddress.mElement = 1;
        OSStatus result = AudioObjectAddPropertyListener(deviceID, &volumePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
        if(kAudioHardwareNoError != result) {
            // Handle the error
        }
        Float32 volume = 0;
        UInt32 dataSize = sizeof(volume);
        result = AudioObjectGetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, &dataSize, &volume);
        
        if(kAudioHardwareNoError != result) {
            // Handle the error
        }
        self.lockedVolume = volume;

        volumePropertyAddress.mElement = 2;
        result = AudioObjectAddPropertyListener(deviceID, &volumePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
        if(kAudioHardwareNoError != result) {
            // Handle the error
        }
    }
    [self.levelItem setTitle:[NSString stringWithFormat:@"Level: %f", self.lockedVolume]];
    
    AudioObjectPropertyAddress mutePropertyAddress = {
        kAudioDevicePropertyMute,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster
    };
    
    if(AudioObjectHasProperty(deviceID, &mutePropertyAddress)) {
        OSStatus result = AudioObjectAddPropertyListener(deviceID, &mutePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
        if(kAudioHardwareNoError != result) {
            // Handle the error
        }
    }
    else {
        // Typically the L and R channels are 1 and 2 respectively, but could be different
        mutePropertyAddress.mElement = 1;
        OSStatus result = AudioObjectAddPropertyListener(deviceID, &mutePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
        if(kAudioHardwareNoError != result) {
            // Handle the error
        }
        
        mutePropertyAddress.mElement = 2;
        result = AudioObjectAddPropertyListener(deviceID, &mutePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
        if(kAudioHardwareNoError != result) {
            // Handle the error
        }
    }
}


static OSStatus myAudioObjectPropertyListenerProc(AudioObjectID                         inObjectID,
                                  UInt32                                inNumberAddresses,
                                  const AudioObjectPropertyAddress      inAddresses[],
                                  void                                  *inClientData)
{
    for(UInt32 addressIndex = 0; addressIndex < inNumberAddresses; ++addressIndex) {
        AudioObjectPropertyAddress currentAddress = inAddresses[addressIndex];
        
        switch(currentAddress.mSelector) {
            case kAudioDevicePropertyVolumeScalar:
            {
                Float32 volume = 0;
                UInt32 dataSize = sizeof(volume);
                OSStatus result = AudioObjectGetPropertyData(inObjectID, &currentAddress, 0, NULL, &dataSize, &volume);
                
                if(kAudioHardwareNoError != result) {
                    // Handle the error
                    continue;
                }
          //      NSLog(@"Volume: %f", volume);
                
                if ([(__bridge AppDelegate *)inClientData locked]) {
                    if (volume != [(__bridge AppDelegate *)inClientData lockedVolume]) {
                        volume = [(__bridge AppDelegate *)inClientData lockedVolume];
                        OSStatus result = AudioObjectSetPropertyData(inObjectID, &currentAddress, 0, NULL, dataSize, &volume);
                        if(kAudioHardwareNoError != result) {
                            // Handle the error
                            continue;
                        }
                    }
                }
                else {
                    [(__bridge AppDelegate *)inClientData setLockedVolume:volume];
                    [[(__bridge AppDelegate *)inClientData levelItem] setTitle:[NSString stringWithFormat:@"Level: %f", volume]];
                }
                
                
                break;
            }
            case kAudioDevicePropertyMute:
            {
                if ([(__bridge AppDelegate *)inClientData locked]) {
                    UInt32 mute = 0;
                    UInt32 dataSize = sizeof(mute);
                    OSStatus result = AudioObjectGetPropertyData(inObjectID, &currentAddress, 0, NULL, &dataSize, &mute);
                    
                    if(kAudioHardwareNoError != result) {
                        // Handle the error
                        continue;
                    }
                    //   NSLog(@"Mute: %u", (unsigned int)mute);
                    if (mute) {
                        mute = 0;
                        OSStatus result = AudioObjectSetPropertyData(inObjectID, &currentAddress, 0, NULL, dataSize, &mute);
                        if(kAudioHardwareNoError != result) {
                            // Handle the error
                            continue;
                        }
                        
                    }
                }
                
                
                
                break;
            }
        }
    }
    return kAudioHardwareNoError;
}

- (IBAction)lock:(id)sender {
    self.locked = YES;
    [self.statusItem setTitle:@"Volume-Locked"];
}

- (IBAction)unlock:(id)sender {
    AuthorizationRights *authorizedRights;
    AuthorizationItem myItems[1];
    
    myItems[0].name = "org.elmercat.volume-lock.edit";
    myItems[0].valueLength = 0;
    myItems[0].value = NULL;
    myItems[0].flags = 0;
    
    AuthorizationRights myRights;
    myRights.count = sizeof (myItems) / sizeof (myItems[0]);
    myRights.items = myItems;
    
    OSStatus osStatus = AuthorizationCopyRights (
                                                 authorizationRef,
                                                 &myRights,
                                                 NULL,
                                                 kAuthorizationFlagExtendRights + kAuthorizationFlagInteractionAllowed + kAuthorizationFlagDestroyRights,
                                                 &authorizedRights
                                                 );
    //   NSLog(@"osStatus: %d", osStatus);
    
    if (!osStatus) {
        self.locked = NO;
        [self.statusItem setTitle:@"Volume-Unlocked"];
    }
}
@end
