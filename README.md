# VolumeLock
OS X Objective-C Status Bar app that locks the currently set audio volume level

The app works by reading audio device properties, and setting up listeners for changes. If a user changes the volume setting, VolumeLock immediately changes it back to the locked setting.

Once locked, an Administrator authentication is required to unlock the volume setting again.

(Initial commit in this repository was built in 2013, and was targeting OS X 10.7)
