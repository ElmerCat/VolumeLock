//
//  AppDelegate.h
//  VolumeControlLock
//
//  Created by Elmer on 2/8/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioServices.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    AuthorizationRef authorizationRef;
}

@property (weak) IBOutlet NSMenu *statusMenu;
@property NSStatusItem *statusItem;
@property Float32 lockedVolume;
@property BOOL locked;
@property (weak) IBOutlet NSMenuItem *levelItem;
- (IBAction)lock:(id)sender;
- (IBAction)unlock:(id)sender;

@end
