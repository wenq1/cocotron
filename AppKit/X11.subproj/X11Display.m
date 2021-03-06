/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


#import "X11Display.h"
#import "X11Window.h"
#import <AppKit/NSScreen.h>
#import <AppKit/NSApplication.h>
#import <AppKit/X11InputSource.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>
#import <AppKit/TTFFont.h>
#import <fcntl.h>

@implementation NSDisplay(X11)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([X11Display class],0,NULL);
}

@end

@implementation X11Display

static int errorHandler(Display* display,
                        XErrorEvent* errorEvent) {
   return [(X11Display*)[X11Display currentDisplay] handleError:errorEvent];
}

-(id)init
{
   if(self=[super init])
   {
      _display=XOpenDisplay(NULL);
      if(!_display)
         _display=XOpenDisplay(":0");

      if(!_display) {
         [self release];
         return nil;
      }
      
      if(NSDebugEnabled)
         XSynchronize(_display, True);
      XSetErrorHandler(errorHandler);
      _windowsByID=[NSMutableDictionary new];
      [self performSelector:@selector(setupEventHandling) withObject:nil afterDelay:0.0];
   }
   return self;
}

-(void)dealloc
{
   if(_display)
      XCloseDisplay(_display);
   [_windowsByID release];
   [super dealloc];
}

-(CGWindow *)windowWithFrame:(NSRect)frame styleMask:(unsigned)styleMask backingType:(unsigned)backingType {
	return [[[X11Window alloc] initWithFrame:frame styleMask:styleMask isPanel:NO backingType:backingType] autorelease];
}


-(CGWindow *)panelWithFrame:(NSRect)frame styleMask:(unsigned)styleMask backingType:(unsigned)backingType {
	return [[[X11Window alloc] initWithFrame:frame styleMask:styleMask isPanel:YES backingType:backingType] autorelease];
}


-(Display*)display
{
   return _display;
}

-(NSArray *)screens {
   NSRect frame=NSMakeRect(0, 0,
                           DisplayWidth(_display, DefaultScreen(_display)),
                           DisplayHeight(_display, DefaultScreen(_display)));
   return [NSArray arrayWithObject:[[[NSScreen alloc] initWithFrame:frame visibleFrame:frame] autorelease]];
}

-(NSPasteboard *)pasteboardWithName:(NSString *)name {
   NSUnimplementedMethod();
   return nil;
}

-(NSDraggingManager *)draggingManager {
//   NSUnimplementedMethod();
   return nil;
}



-(NSColor *)colorWithName:(NSString *)colorName {
   
   if([colorName isEqual:@"controlColor"])
      return [NSColor lightGrayColor];
   if([colorName isEqual:@"disabledControlTextColor"])
      return [NSColor grayColor];
   if([colorName isEqual:@"controlTextColor"])
      return [NSColor blackColor];
   if([colorName isEqual:@"menuBackgroundColor"])
      return [NSColor lightGrayColor];
   if([colorName isEqual:@"controlShadowColor"])
      return [NSColor darkGrayColor];
   if([colorName isEqual:@"selectedControlColor"])
      return [NSColor blueColor];
   if([colorName isEqual:@"controlBackgroundColor"])
      return [NSColor whiteColor];
   if([colorName isEqual:@"controlLightHighlightColor"])
      return [NSColor lightGrayColor];

   if([colorName isEqual:@"textBackgroundColor"])
      return [NSColor whiteColor];
   if([colorName isEqual:@"textColor"])
      return [NSColor blackColor];
   if([colorName isEqual:@"menuItemTextColor"])
      return [NSColor blackColor];
   if([colorName isEqual:@"selectedMenuItemTextColor"])
      return [NSColor whiteColor];
   if([colorName isEqual:@"selectedMenuItemColor"])
      return [NSColor blueColor];
   if([colorName isEqual:@"selectedControlTextColor"])
      return [NSColor blackColor];
   
   NSLog(@"%@", colorName);
   
   return [NSColor redColor];
   
}

-(void)_addSystemColor:(NSColor *) result forName:(NSString *)colorName {
   NSUnimplementedMethod();
}

-(NSTimeInterval)textCaretBlinkInterval {
   return 0.5;
}

-(void)hideCursor {
   NSUnimplementedMethod();
}

-(void)unhideCursor {
   NSUnimplementedMethod();
}

// Arrow, IBeam, HorizontalResize, VerticalResize
-(id)cursorWithName:(NSString *)name {
   NSUnimplementedMethod();
   return nil;
}

-(void)setCursor:(id)cursor {
   NSUnimplementedMethod();
}

-(void)beep {
   XBell(_display, 100);
}

-(NSSet *)allFontFamilyNames {
   return [TTFFont allFontFamilyNames];
}

-(NSArray *)fontTypefacesForFamilyName:(NSString *)name {
   return [TTFFont fontTypefacesForFamilyName:name];
}

-(float)scrollerWidth {
   return 15.0;
}

-(float)doubleClickInterval {
   return 1.0;
}


-(void)runModalPageLayoutWithPrintInfo:(NSPrintInfo *)printInfo {
   NSUnimplementedMethod();
}

-(int)runModalPrintPanelWithPrintInfoDictionary:(NSMutableDictionary *)attributes {
   NSUnimplementedMethod();
   return 0;
}

-(KGContext *)graphicsPortForPrintOperationWithView:(NSView *)view printInfo:(NSPrintInfo *)printInfo pageRange:(NSRange)pageRange {
   NSUnimplementedMethod();
   return nil;
}

-(int)savePanel:(NSSavePanel *)savePanel runModalForDirectory:(NSString *)directory file:(NSString *)file {
   NSUnimplementedMethod();
   return 0;
}

-(int)openPanel:(NSOpenPanel *)openPanel runModalForDirectory:(NSString *)directory file:(NSString *)file types:(NSArray *)types {
   NSUnimplementedMethod();
   return 0;
}

-(NSPoint)mouseLocation {
   NSUnimplementedMethod();
   return NSMakePoint(0,0);
}

-(void)setWindow:(id)window forID:(XID)i
{
   if(window)
      [_windowsByID setObject:window forKey:[NSNumber numberWithUnsignedLong:(unsigned long)i]];
   else
      [_windowsByID removeObjectForKey:[NSNumber numberWithUnsignedLong:(unsigned long)i]];
}

-(id)windowForID:(XID)i
{
   return [_windowsByID objectForKey:[NSNumber numberWithUnsignedLong:i]];
}

-(void)setupEventHandling {
   [X11InputSource addInputSourceWithDisplay:self];
}

-(NSEvent *)nextEventMatchingMask:(unsigned)mask untilDate:(NSDate *)untilDate inMode:(NSString *)mode dequeue:(BOOL)dequeue;
{
   [self processX11Event];
   return [super nextEventMatchingMask:mask untilDate:untilDate inMode:mode dequeue:dequeue];
}

-(BOOL)processX11Event {
   XEvent e;
   int i;
   int numEvents;
   BOOL ret=NO;
   int connectionNumber=ConnectionNumber(_display);
   int flags=fcntl(connectionNumber, F_GETFL);
   flags&=~O_NONBLOCK;
   fcntl(connectionNumber, F_SETFL, flags | O_NONBLOCK);
   
   NSMutableSet *windowsUsed=[NSMutableSet set];
   
   while(numEvents=XEventsQueued(_display, QueuedAfterFlush)) {
      XNextEvent(_display, &e);
      id window=[self windowForID:e.xany.window];
      [window handleEvent:&e fromDisplay:self];
      [windowsUsed addObject:window];
      ret=YES;
   }
   
   fcntl(connectionNumber, F_SETFL, flags & ~O_NONBLOCK);


   return ret;
}

-(int)handleError:(XErrorEvent*)errorEvent {
   NSLog(@"************** ERROR");
   return 0;
}
@end

#import <AppKit/NSGraphicsStyle.h>

@implementation NSGraphicsStyle (Overrides) 
-(void)drawMenuBranchArrowAtPoint:(NSPoint)point selected:(BOOL)selected {
   NSImage* arrow=[NSImage imageNamed:@"NSMenuArrow"];
   point.y+=5;
   point.x-=2;
   [arrow compositeToPoint:point operation:NSCompositeSourceOver];
}

@end