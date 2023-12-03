//
//  AppDelegate.h
//  VolumeControlLock
//
//  Created by Elmer on 2/8/13.
//  New Version 1.2 by Elmer on 12/1/23.
//  Copyright (c) 2013, 2023 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioServices.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSAttributedString *lockedTitle;
    NSAttributedString *unlockedTitle;
 }

@property (weak) IBOutlet NSMenu *statusMenu;
@property NSStatusItem *statusItem;
@property Float32 lockedVolume;
@property BOOL locked;
@property (weak) IBOutlet NSMenuItem *levelItem;
- (IBAction)lock:(id)sender;
- (IBAction)unlock:(id)sender;
- (bool) authorizeVolumeLock;

@end
