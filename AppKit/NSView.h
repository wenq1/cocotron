/* Copyright (c) 2006-2007 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSResponder.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/AppKitExport.h>
#import <ApplicationServices/ApplicationServices.h>

@class NSWindow, NSMenu, NSCursor, NSPasteboard, NSImage, NSScrollView;

typedef int NSTrackingRectTag;
typedef int NSToolTipTag;

enum {
   NSViewNotSizable=0x00,
   NSViewMinXMargin=0x01,
   NSViewWidthSizable=0x02,
   NSViewMaxXMargin=0x04,
   NSViewMinYMargin=0x08,
   NSViewHeightSizable=0x10,
   NSViewMaxYMargin=0x20
};

typedef enum {
   NSNoBorder,
   NSLineBorder,
   NSBezelBorder,
   NSGrooveBorder
} NSBorderType;

APPKIT_EXPORT NSString *NSViewFrameDidChangeNotification;
APPKIT_EXPORT NSString *NSViewBoundsDidChangeNotification;
APPKIT_EXPORT NSString *NSViewFocusDidChangeNotification;

@interface NSView : NSResponder {
   NSRect          _frame;
   NSRect          _bounds;
   NSWindow       *_window;
   NSMenu         *_menu;
   NSView         *_superview;
   NSMutableArray *_subviews;
   NSView         *_nextKeyView;
   NSView         *_previousKeyView;
   BOOL            _isHidden;
   BOOL            _postsNotificationOnFrameChange;
   BOOL            _postsNotificationOnBoundsChange;
   BOOL            _autoresizesSubviews;
   BOOL            _inLiveResize;
   unsigned        _autoresizingMask;
   int             _tag;
   NSArray        *_draggedTypes;
   NSToolTipTag    _defaultToolTipTag;
   NSString       *_toolTip;
   NSMutableArray *_trackingAreas;
   NSRect          _invalidRect;

   BOOL              _validTransforms;
   CGAffineTransform _transformFromWindow;
   CGAffineTransform _transformToWindow;
   NSRect            _visibleRect;
}

+(NSView *)focusView;
+(NSMenu *)defaultMenu;

-initWithFrame:(NSRect)frame;

-(NSRect)frame;
-(NSRect)bounds;
-(BOOL)postsFrameChangedNotifications;
-(BOOL)postsBoundsChangedNotifications;

-(NSWindow *)window;
-superview;
-(BOOL)isDescendantOf:(NSView *)other;
-(NSScrollView *)enclosingScrollView;

-(NSArray *)subviews;
-(BOOL)autoresizesSubviews;
-(unsigned)autoresizingMask;

-(int)tag;
-(BOOL)isFlipped;
-(BOOL)isOpaque;
-(int)gState;
-(NSRect)visibleRect;

-(BOOL)isHidden;
-(BOOL)isHiddenOrHasHiddenAncestor;
-(void)setHidden:(BOOL)flag;

-(BOOL)canBecomeKeyView;

-(NSView *)nextKeyView;
-(NSView *)nextValidKeyView;

-(NSView *)previousKeyView;
-(NSView *)previousValidKeyView;

-(NSMenu *)menuForEvent:(NSEvent *)event;
-(NSString *)toolTip;

-viewWithTag:(int)tag;
-(NSView *)hitTest:(NSPoint)point;

-(NSPoint)convertPoint:(NSPoint)point fromView:(NSView *)viewOrNil;
-(NSPoint)convertPoint:(NSPoint)point toView:(NSView *)viewOrNil;
-(NSSize)convertSize:(NSSize)size fromView:(NSView *)viewOrNil;
-(NSSize)convertSize:(NSSize)size toView:(NSView *)viewOrNil;
-(NSRect)convertRect:(NSRect)rect fromView:(NSView *)viewOrNil;
-(NSRect)convertRect:(NSRect)rect toView:(NSView *)viewOrNil;
-(NSRect)centerScanRect:(NSRect)rect;

-(void)setFrame:(NSRect)frame;
-(void)setFrameSize:(NSSize)size;
-(void)setFrameOrigin:(NSPoint)origin;

-(void)setBounds:(NSRect)bounds;
-(void)setBoundsSize:(NSSize)size;
-(void)setBoundsOrigin:(NSPoint)origin;

-(void)setPostsFrameChangedNotifications:(BOOL)flag;
-(void)setPostsBoundsChangedNotifications:(BOOL)flag;

-(void)addSubview:(NSView *)view;
-(void)addSubview:(NSView *)view positioned:(NSWindowOrderingMode)ordering relativeTo:(NSView *)relativeTo;
-(void)replaceSubview:(NSView *)oldView with:(NSView *)newView;
-(void)setAutoresizesSubviews:(BOOL)flag;
-(void)setAutoresizingMask:(unsigned int)mask;

-(void)setTag:(int)tag;

-(void)setNextKeyView:(NSView *)next;

-(void)setToolTip:(NSString *)string;
-(NSToolTipTag)addToolTipRect:(NSRect)rect owner:object userData:(void *)userData;
-(void)removeToolTip:(NSToolTipTag)tag;
-(void)removeAllToolTips;

-(void)addCursorRect:(NSRect)rect cursor:(NSCursor *)cursor;
-(void)removeCursorRect:(NSRect)rect cursor:(NSCursor *)cursor;
-(void)discardCursorRects;
-(void)resetCursorRects;

-(NSArray *)trackingAreas;
-(void)addTrackingArea:(NSTrackingArea *)trackingArea;
-(void)removeTrackingArea:(NSTrackingArea *)trackingArea;
-(void)updateTrackingAreas;

-(NSTrackingRectTag)addTrackingRect:(NSRect)rect owner:object userData:(void *)userData assumeInside:(BOOL)assumeInside;
-(void)removeTrackingRect:(NSTrackingRectTag)tag;

-(void)registerForDraggedTypes:(NSArray *)types;
-(void)unregisterDraggedTypes;

-(void)removeFromSuperview;
-(void)removeFromSuperviewWithoutNeedingDisplay;

-(void)viewWillMoveToWindow:(NSWindow *)window;
-(void)viewWillMoveToSuperview:(NSView *)view;

-(void)resizeSubviewsWithOldSize:(NSSize)oldSize;
-(void)resizeWithOldSuperviewSize:(NSSize)oldSize;

-(BOOL)inLiveResize;
-(void)viewWillStartLiveResize;
-(void)viewDidEndLiveResize;

-(void)scrollPoint:(NSPoint)point;
-(BOOL)scrollRectToVisible:(NSRect)rect;
-(BOOL)mouse:(NSPoint)point inRect:(NSRect)rect;

-(void)allocateGState;
-(void)releaseGState;
-(void)setUpGState;

-(BOOL)needsDisplay;
-(void)setNeedsDisplayInRect:(NSRect)rect;
-(void)setNeedsDisplay:(BOOL)flag;

-(BOOL)canDraw;
-(void)lockFocus;
-(BOOL)lockFocusIfCanDraw;
-(void)unlockFocus;

-(NSView *)opaqueAncestor;
-(void)display;
-(void)displayIfNeeded;
-(void)displayIfNeededInRect:(NSRect)rect;
-(void)displayIfNeededInRectIgnoringOpacity:(NSRect)rect;
-(void)displayRect:(NSRect)rect;
-(void)displayRectIgnoringOpacity:(NSRect)rect;
-(void)drawRect:(NSRect)rect;

-(BOOL)autoscroll:(NSEvent *)event;
-(void)scrollRect:(NSRect)rect by:(NSSize)delta;

-(void)print:sender;

-(void)beginDocument;
-(void)endDocument;

-(void)beginPageInRect:(NSRect)rect atPlacement:(NSPoint)placement;
-(void)endPage;

-(float)widthAdjustLimit;
-(float)heightAdjustLimit;
-(void)adjustPageWidthNew:(float *)adjustedRight left:(float)left right:(float)right limit:(float)limit;
-(void)adjustPageHeightNew:(float *)adjustedBottom top:(float)top bottom:(float)bottom limit:(float)limit;

-(BOOL)knowsPageRange:(NSRange *)range;
-(NSPoint)locationOfPrintRect:(NSRect)rect;
-(NSRect)rectForPage:(int)page;

-(NSData *)dataWithEPSInsideRect:(NSRect)rect;
-(NSData *)dataWithPDFInsideRect:(NSRect)rect;

-(void)writeEPSInsideRect:(NSRect)rect toPasteboard:(NSPasteboard *)pasteboard;
-(void)writePDFInsideRect:(NSRect)rect toPasteboard:(NSPasteboard *)pasteboard;

-(void)dragImage:(NSImage *)image at:(NSPoint)location offset:(NSSize)offset event:(NSEvent *)event pasteboard:(NSPasteboard *)pasteboard source:source slideBack:(BOOL)slideBack;

-(BOOL)dragFile:(NSString *)path fromRect:(NSRect)rect slideBack:(BOOL)slideBack event:(NSEvent *)event;

-(NSPoint)convertPointFromBase:(NSPoint)aPoint;
-(NSPoint)convertPointToBase:(NSPoint)aPoint;
-(NSSize)convertSizeFromBase:(NSSize)aSize;
-(NSSize)convertSizeToBase:(NSSize)aSize;
-(NSRect)convertRectFromBase:(NSRect)aRect;
-(NSRect)convertRectToBase:(NSRect)aRect;

// private,move
-(NSArray *)_draggedTypes;
-(void)_setWindow:(NSWindow *)window;

@end

@interface NSObject(NSView_toolTipOwner)
-(NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data;
@end

