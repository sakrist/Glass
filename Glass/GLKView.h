//
//  GLKView.h
//  3D4MEngine
//
//  Created by Vladmir on 14/01/2013.
//  Copyright (c) 2013 3D4Medical, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 Enums for color buffer formats.
 */
typedef enum
{
	GLKViewDrawableColorFormatRGBA8888 = 0,
	GLKViewDrawableColorFormatRGB565,
} GLKViewDrawableColorFormat;

/*
 Enums for depth buffer formats.
 */
typedef enum
{
	GLKViewDrawableDepthFormatNone = 0,
	GLKViewDrawableDepthFormat16,
	GLKViewDrawableDepthFormat24,
} GLKViewDrawableDepthFormat;

/*
 Enums for stencil buffer formats.
 */
typedef enum
{
	GLKViewDrawableStencilFormatNone = 0,
	GLKViewDrawableStencilFormat8,
} GLKViewDrawableStencilFormat;

/*
 Enums for MSAA.
 */
typedef enum
{
	GLKViewDrawableMultisampleNone = 0,
	GLKViewDrawableMultisample4X,
} GLKViewDrawableMultisample;


@protocol GLKViewDelegate;

@interface GLKView : NSOpenGLView

@property (nonatomic, readonly) GLsizei drawableWidth;
@property (nonatomic, readonly) GLsizei drawableHeight;

@property (nonatomic) GLKViewDrawableColorFormat drawableColorFormat;
@property (nonatomic) GLKViewDrawableDepthFormat drawableDepthFormat;
@property (nonatomic) GLKViewDrawableStencilFormat drawableStencilFormat;
@property (nonatomic) GLKViewDrawableMultisample drawableMultisample;

@property (nonatomic, assign) IBOutlet id <GLKViewDelegate> delegate;

@property (nonatomic) BOOL userInteractionEnabled;

- (void) bindDrawable;

- (void) setNeedsDisplay;

- (void) pause;
- (void) resume;

@end


@protocol GLKViewDelegate <NSObject>

@required

- (void) glkViewControllerUpdate:(id)controller;

- (void) glkView:(GLKView *)view drawInRect:(CGRect)rect;

- (void) glkView:(GLKView *)view resizeWithSize:(CGSize)size;


@end