//
//  GLKView.m
//  3D4MEngine
//
//  Created by Vladmir on 14/01/2013.
//  Copyright (c) 2013 3D4Medical, LLC. All rights reserved.
//

#import <objc/runtime.h>

#import "GLKView.h"

#import <CoreVideo/CoreVideo.h>


@interface GLKView () {
    CVDisplayLinkRef displayLink;
    
    BOOL _allowInteraction;
    
    BOOL _pause;
    
    BOOL _loadView;
    
    float last;
    
    NSViewController *_controller;
}

- (CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime;

@end


// This is the renderer output callback function
static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    

    CVReturn result = [(__bridge GLKView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}


@implementation GLKView

- (void)_setViewController:(NSViewController*)controller {
    _controller = controller;
}

- (void) pause {
    _pause = YES;
}

- (void) resume {
    _pause = NO;
    _userInteractionEnabled = YES;
}

- (void) setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    _userInteractionEnabled = userInteractionEnabled;
//    DLog(@" %@", [[NSThread callStackSymbols] objectAtIndex:1]);
}

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime {
    
    if (_pause) {
        return kCVReturnSuccess;
    }
    
    float deltaTime = 1.0 / (outputTime->rateScalar * (double)outputTime->videoTimeScale / (double)outputTime->videoRefreshPeriod);
//    NSLog(@"%f %f %f", deltaTime, (float)outputTime->videoTimeScale, (float)outputTime->videoRefreshPeriod);
    
    if (last <= deltaTime) {
        last += deltaTime;
        return kCVReturnSuccess;
    }
    last = deltaTime;
	// There is no autorelease pool when this method is called
	// because it will be called from a background thread
	// It's important to create one or you will leak objects
    
	@autoreleasepool {
        [self drawView];
//        [self performSelectorOnMainThread:@selector(drawView) withObject:nil waitUntilDone:YES];
    }

	return kCVReturnSuccess;
}

- (void) bindDrawable {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (void) awakeFromNib {
    
    _userInteractionEnabled = YES;
    
    NSOpenGLPixelFormatAttribute attrs[] =
	{

        NSOpenGLPFAColorSize    , 32 ,
        NSOpenGLPFAAlphaSize    , 8  ,
        NSOpenGLPFADepthSize    , 24 ,
        NSOpenGLPFAAccelerated  ,
        NSOpenGLPFADoubleBuffer ,
        NSOpenGLPFASupersample  ,
        NSOpenGLPFASampleBuffers, 1  ,
        NSOpenGLPFASamples      , 4  ,
        
// Must specify the 3.2 Core Profile to use OpenGL 3.2
#if GL_PRACTICES_SUPPORT_GL3
		NSOpenGLPFAOpenGLProfile,
		NSOpenGLProfileVersion3_2Core,
#endif
		0
	};
	
	NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	
	if (!pf)
	{
		NSLog(@"No OpenGL pixel format");
	}
    
    NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
    
    [self setPixelFormat:pf];
    
    [self setOpenGLContext:context];
}

- (void) prepareOpenGL {
    
	[super prepareOpenGL];
	
    _drawableWidth = [self bounds].size.width;
    _drawableHeight = [self bounds].size.height;

    
	// Make all the OpenGL calls to setup rendering
	//  and build the necessary rendering objects
	[self initGL];
	
	// Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &displayLinkCallback, (__bridge void*)self);
	
	// Set the display link for the current renderer
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
	// Activate the display link
	CVDisplayLinkStart(displayLink);
}

- (void) initGL {
    
    if ([[NSScreen mainScreen] backingScaleFactor] == 2) {
        [self setWantsBestResolutionOpenGLSurface:YES];
    }
    
	// Make this openGL context current to the thread
	// (i.e. all openGL on this thread calls will go to this context)
	[[self openGLContext] makeCurrentContext];
	
    _allowInteraction = YES;
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);

    
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];

    
    if ([_delegate respondsToSelector:@selector(setupGL)]) {
        [_delegate performSelector:@selector(setupGL)];
    }
}

- (void) reshape {
    
	[super reshape];
	
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously when resizing
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	NSRect rect = [self bounds];

    _drawableWidth = rect.size.width * [[NSScreen mainScreen] backingScaleFactor];
    _drawableHeight = rect.size.height * [[NSScreen mainScreen] backingScaleFactor];
    
    glViewport(0, 0, _drawableWidth, _drawableHeight);
	
    if (_delegate) {
        [_delegate glkView:self resizeWithSize:rect.size];
    }
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void) drawView {
    
	[[self openGLContext] makeCurrentContext];
    
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously	when resizing
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	if (_delegate) {
        
        [_delegate glkViewControllerUpdate:_delegate];
        
        [_delegate glkView:self drawInRect:[self frame]];
    }
	

    
	CGLFlushDrawable([[self openGLContext] CGLContextObj]);
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void) setNeedsDisplay {
    [self setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    if (!_loadView) {
        _loadView = YES;
//        [(NSObject*)_delegate performSelector:@selector(viewDidLoad) withObject:nil afterDelay:0.3];
    }
}


- (void) mouseDragged:(NSEvent *)theEvent {
    [_delegate performSelector:@selector(mouseDragged:) withObject:theEvent];
}

- (void)scrollWheel:(NSEvent *)event {
    [_delegate performSelector:@selector(scrollWheel:) withObject:event];
}

@end
