//
//  VBRenderController.h
//  Glass
//
//  Created by Volodymyr Boichentsov on 21/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLKView.h"

@interface VBRenderController : NSViewController

@property (nonatomic, retain) IBOutlet GLKView *glView;

@end
