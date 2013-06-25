//
//  VBAppDelegate.m
//  Glass
//
//  Created by Volodymyr Boichentsov on 21/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import "VBAppDelegate.h"

@implementation VBAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void) applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"applicationWillTerminate");
    [_controller.glView pause];
}

- (void) applicationWillHide:(NSNotification *)notification {
    NSLog(@"applicationWillHide");
    [_controller.glView pause];
}


@end
