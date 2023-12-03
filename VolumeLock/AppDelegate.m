//
//  AppDelegate.m
//  VolumeControlLock
//
//  Created by Elmer on 2/8/13.
//  New Version 1.2 by Elmer on 12/1/23.
//  Copyright (c) 2013, 2023 ElmerCat. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

-(void)awakeFromNib{
    
    // Set up the Status Bar Item with data from User Preferences
    
    lockedTitle = [[NSAttributedString alloc] initWithString:@"Volume\nLocked" attributes:@{ NSFontAttributeName: [NSFont menuBarFontOfSize:8] }];
    unlockedTitle = [[NSAttributedString alloc] initWithString:@"Volume-Unlocked" attributes:@{ NSFontAttributeName: [NSFont boldSystemFontOfSize:0], NSForegroundColorAttributeName: [NSColor redColor] }];
    
    self.locked = [NSUserDefaults.standardUserDefaults boolForKey:@"locked"];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.statusMenu];
    if (self.locked == true) {
        self.lockedVolume = [NSUserDefaults.standardUserDefaults floatForKey:@"lockedvolume"];
        [self.statusItem.button setAttributedTitle: lockedTitle];
        [self.statusItem.button setImage:[NSImage imageNamed: NSImageNameLockLockedTemplate]];
    }
    else {
        [self.statusItem.button setAttributedTitle: unlockedTitle];
        [self.statusItem.button setImage:[NSImage imageNamed: NSImageNameLockUnlockedTemplate]];
    }
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
        
    AudioObjectPropertyAddress devicePropertyAddress = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    Float32 volume = self.lockedVolume;
    UInt32 volumeSize = sizeof(volume);

    AudioDeviceID deviceID;
    UInt32 deviceIDSize = sizeof(deviceID);
    AudioObjectGetPropertyData(kAudioObjectSystemObject, &devicePropertyAddress, 0, NULL, &deviceIDSize, &deviceID);
    
    // Some devices (but not many) support a master channel
    AudioObjectPropertyAddress volumePropertyAddress = {
        kAudioDevicePropertyVolumeScalar,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster
    };
    
    // Set or Get the device volume properties and add property listeners
    
    if(AudioObjectHasProperty(deviceID, &volumePropertyAddress)) {  // The device has a Master Channel

        if (self.locked == true) {
            AudioObjectSetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, volumeSize, &volume);
        }
        else {
            AudioObjectGetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, &volumeSize, &volume);
            self.lockedVolume = volume;
        }
        AudioObjectAddPropertyListener(deviceID, &volumePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
        
        // end of Master Channel code
        
    }
    else {  //  the L and R channels are 1 and 2 respectively
        
        volumePropertyAddress.mElement = 1;
        if (self.locked == true) {
            AudioObjectSetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, volumeSize, &volume);
        }
        else {
            AudioObjectGetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, &volumeSize, &volume);
            self.lockedVolume = volume;
        }
        AudioObjectAddPropertyListener(deviceID, &volumePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
        
        volumePropertyAddress.mElement = 2;
        if (self.locked == true) {
            AudioObjectSetPropertyData(deviceID, &volumePropertyAddress, 0, NULL, volumeSize, &volume);
        }
       AudioObjectAddPropertyListener(deviceID, &volumePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
    }
    
    // Add Mute property listeners
    
    AudioObjectPropertyAddress mutePropertyAddress = {
        kAudioDevicePropertyMute,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster
    };
    
    if(AudioObjectHasProperty(deviceID, &mutePropertyAddress)) {
        AudioObjectAddPropertyListener(deviceID, &mutePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
    }
    else {
        // Typically the L and R channels are 1 and 2 respectively, but could be different
        mutePropertyAddress.mElement = 1;
        AudioObjectAddPropertyListener(deviceID, &mutePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
        
        mutePropertyAddress.mElement = 2;
        AudioObjectAddPropertyListener(deviceID, &mutePropertyAddress, myAudioObjectPropertyListenerProc, (__bridge void *)(self));
    }
    
    // Set the volume level menu item string
    [self.levelItem setTitle:[NSString stringWithFormat:@"Level: %f", self.lockedVolume]];
    
}

// Property listener for either volume or mute changes

static OSStatus myAudioObjectPropertyListenerProc(AudioObjectID                         inObjectID,
                                  UInt32                                inNumberAddresses,
                                  const AudioObjectPropertyAddress      inAddresses[],
                                  void                                  *inClientData)
{
    for(UInt32 addressIndex = 0; addressIndex < inNumberAddresses; ++addressIndex) {
       
        AudioObjectPropertyAddress currentAddress = inAddresses[addressIndex];
        switch(currentAddress.mSelector) {
        
            case kAudioDevicePropertyVolumeScalar: {
                Float32 volume = 0;
                UInt32 volumeSize = sizeof(volume);
                AudioObjectGetPropertyData(inObjectID, &currentAddress, 0, NULL, &volumeSize, &volume);
                
                //If locked, change the volume back to the locked setting
                if ([(__bridge AppDelegate *)inClientData locked]) {
                    if (volume != [(__bridge AppDelegate *)inClientData lockedVolume]) {
                        volume = [(__bridge AppDelegate *)inClientData lockedVolume];
                        AudioObjectSetPropertyData(inObjectID, &currentAddress, 0, NULL, volumeSize, &volume);
                    }
                }

                // If unlocked, update the displayed Level setting in the menu
                else {
                    [(__bridge AppDelegate *)inClientData setLockedVolume:volume];
                    [[(__bridge AppDelegate *)inClientData levelItem] setTitle:[NSString stringWithFormat:@"Level: %f", volume]];
                }
                break;
            }
            
            case kAudioDevicePropertyMute: {  
                // If locked, always turn mute off
                if ([(__bridge AppDelegate *)inClientData locked]) {
                    UInt32 mute = 0;
                    UInt32 muteSize = sizeof(mute);
                    AudioObjectGetPropertyData(inObjectID, &currentAddress, 0, NULL, &muteSize, &mute);
                    
                    if (mute) {
                        mute = 0;
                        AudioObjectSetPropertyData(inObjectID, &currentAddress, 0, NULL, muteSize, &mute);
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
    [self.statusItem.button setAttributedTitle:lockedTitle];
    [self.statusItem.button setImage:[NSImage imageNamed: NSImageNameLockLockedTemplate]];
    [NSUserDefaults.standardUserDefaults setFloat:self.lockedVolume forKey:@"lockedvolume"];
    [NSUserDefaults.standardUserDefaults setBool:true forKey:@"locked"];
}

- (IBAction)unlock:(id)sender {
    
    if (self.authorizeVolumeLock == true) {
        self.locked = NO;
        [self.statusItem.button setAttributedTitle:unlockedTitle];
        [self.statusItem.button setImage:[NSImage imageNamed: NSImageNameLockUnlockedTemplate]];
        [NSUserDefaults.standardUserDefaults setBool:false forKey:@"locked"];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    
    if (self.locked == true) {  // Get authorization for app to Quit
         if (self.authorizeVolumeLock != true) {
            return NSTerminateCancel;
        }
    }
    return NSTerminateNow;
}

- (bool) authorizeVolumeLock {

    // Ask for Administrator authentication
    AuthorizationRef authorizationRef;
    AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment,
                                    kAuthorizationFlagDefaults, &authorizationRef);
    OSStatus osStatus = AuthorizationRightSet(authorizationRef, "org.elmercat.volume-lock.edit",
                          CFSTR(kAuthorizationRuleAuthenticateAsAdmin), CFSTR("Authorize changing the Volume"), NULL, NULL);
    if (!osStatus) {
        return true;
    }
    return false;
}



@end
