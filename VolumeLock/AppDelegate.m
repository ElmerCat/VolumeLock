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

    self.locked = [NSUserDefaults.standardUserDefaults boolForKey:@"locked"];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.statusMenu];
    if (self.locked == true) {
        self.lockedVolume = [NSUserDefaults.standardUserDefaults floatForKey:@"lockedvolume"];
        [self.statusItem setTitle:@"Volume-Locked"];
    }
    else {
        [self.statusItem setTitle:@"Volume-Unlocked"];
    }
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
    
    
    Float32 volume = self.lockedVolume;
    UInt32 volumeSize = sizeof(volume);

    AudioDeviceID deviceID;
    UInt32 deviceIDSize = sizeof(deviceID);
    OSStatus result = AudioObjectGetPropertyData(kAudioObjectSystemObject, &devicePropertyAddress, 0, NULL, &deviceIDSize, &deviceID);
    
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

        if (self.locked == true) {
            
            result = AudioObjectSetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, volumeSize, &volume);
            if(kAudioHardwareNoError != result) {
                // Handle the error
             }
            
        }
        else {
            result = AudioObjectGetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, &volumeSize, &volume);
            
            if(kAudioHardwareNoError != result) {
                // Handle the error
            }
            self.lockedVolume = volume;

        }
        
        result = AudioObjectAddPropertyListener(deviceID, &volumePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
        if(kAudioHardwareNoError != result) {
            // Handle the error
        }
        
        // end of Master Channel code
        
    }
    else {
        // Typically the L and R channels are 1 and 2 respectively, but could be different
        volumePropertyAddress.mElement = 1;
        
        
        if (self.locked == true) {
            
            result = AudioObjectSetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, volumeSize, &volume);
            if(kAudioHardwareNoError != result) {
                // Handle the error
            }

        }

        else {
            result = AudioObjectGetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, &volumeSize, &volume);
            
            if(kAudioHardwareNoError != result) {
                // Handle the error
            }
            self.lockedVolume = volume;

        }
        
        
        result = AudioObjectAddPropertyListener(deviceID, &volumePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
        if(kAudioHardwareNoError != result) {
            // Handle the error
        }
        
       volumePropertyAddress.mElement = 2;
        
        if (self.locked == true) {
            
            result = AudioObjectSetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, volumeSize, &volume);
            if(kAudioHardwareNoError != result) {
                // Handle the error
            }
            
        }

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
                UInt32 volumeSize = sizeof(volume);
                OSStatus result = AudioObjectGetPropertyData(inObjectID, &currentAddress, 0, NULL, &volumeSize, &volume);
                
                if(kAudioHardwareNoError != result) {
                    // Handle the error
                    continue;
                }
          //      NSLog(@"Volume: %f", volume);
                
                if ([(__bridge AppDelegate *)inClientData locked]) {
                    if (volume != [(__bridge AppDelegate *)inClientData lockedVolume]) {
                        volume = [(__bridge AppDelegate *)inClientData lockedVolume];
                        OSStatus result = AudioObjectSetPropertyData(inObjectID, &currentAddress, 0, NULL, volumeSize, &volume);
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
                    UInt32 muteSize = sizeof(mute);
                    OSStatus result = AudioObjectGetPropertyData(inObjectID, &currentAddress, 0, NULL, &muteSize, &mute);
                    
                    if(kAudioHardwareNoError != result) {
                        // Handle the error
                        continue;
                    }
                    //   NSLog(@"Mute: %u", (unsigned int)mute);
                    if (mute) {
                        mute = 0;
                        OSStatus result = AudioObjectSetPropertyData(inObjectID, &currentAddress, 0, NULL, muteSize, &mute);
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
    [NSUserDefaults.standardUserDefaults setFloat:self.lockedVolume forKey:@"lockedvolume"];
    [NSUserDefaults.standardUserDefaults setBool:true forKey:@"locked"];
}

- (IBAction)unlock:(id)sender {
    
    if (self.authorizeVolumeLock == true) {
        self.locked = NO;
        [self.statusItem setTitle:@"Volume-Unlocked"];
        [NSUserDefaults.standardUserDefaults setBool:false forKey:@"locked"];

    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    
    if (self.locked == true) {
         if (self.authorizeVolumeLock != true) {
            return NSTerminateCancel;
        }
    }
    return NSTerminateNow;

    
    
}

- (bool) authorizeVolumeLock {
    
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
    if (!osStatus) {
        return true;
    }
    
    return false;
    
}


@end
