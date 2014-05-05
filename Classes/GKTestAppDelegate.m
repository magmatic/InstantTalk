/*
 //  InstantTalk
 //
 //  Copyright (c) 2014 Black Magma Inc. All rights reserved.
 */

#import "GKTestAppDelegate.h"

@implementation GKTestAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {	    
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    NSString *boardName = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? @"GKSessionP2P_iPhone" : @"GKSessionP2P_iPad";
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:boardName bundle: nil];    
    _window.rootViewController = [mainStoryboard instantiateInitialViewController];
    [_window makeKeyAndVisible];
    
    _appControl = (GKTestViewController*) [(UINavigationController*) _window.rootViewController topViewController];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // restore brightness if dimmed
//    if ([UIScreen mainScreen].brightness == 0) {
//      [[UIScreen mainScreen] setBrightness:_appControl.brightness];
//    }
    
    // we might want to suspend the chat service if not in use
//    [_appControl suspend];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // we may need to re-start the chat service if it's not running
    [_appControl resume];
}

@end