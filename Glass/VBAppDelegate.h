//
//  VBAppDelegate.h
//  Glass
//
//  Created by Volodymyr Boichentsov on 21/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "VBRenderController.h"
#import "GLKView.h"

@interface VBAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet VBRenderController *controller;

@end
