/* Copyright (c) 2006-2007 Christopher J. W. Lloyd
                 2009 Markus Hitter <mah@jump-ing.de>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSImageView.h>
#import <AppKit/NSImageCell.h>
#import <AppKit/NSRaise.h>

@implementation NSImageView

+(Class)cellClass {
   return [NSImageCell class];
}

-(BOOL)allowsCutCopyPaste {
   // Because cut, copy, paste isn't implemented yet ...
   return NO;
}

-(BOOL)animates {
   // Because animation isn't implemented yet ...
   return NO;
}

-(NSImage *)image {
   return [_cell image];
}

-(NSImageAlignment)imageAlignment {
   return [_cell imageAlignment];
}

-(NSImageFrameStyle)imageFrameStyle {
   return [_cell imageFrameStyle];
}

-(NSImageScaling)imageScaling {
   return [_cell imageScaling];
}

-(BOOL)isEditable {
   return [_cell isEditable];
}

-(void)setAllowsCutCopyPaste:(BOOL)allow {
   if(allow!=NO)
    NSUnimplementedMethod();
}

-(void)setAnimates:(BOOL)flag {
   if(flag!=NO)
    NSUnimplementedMethod();
}

-(void)setEditable:(BOOL)flag {
   [_cell setEditable:flag];
}

-(void)setImage:(NSImage *)image {
   [_cell setImage:image];
}

-(void)setImageAlignment:(NSImageAlignment)alignment {
   [_cell setImageAlignment:alignment];
}

-(void)setImageFrameStyle:(NSImageFrameStyle)frameStyle {
   [_cell setImageFrameStyle:frameStyle];
}

-(void)setImageScaling:(NSImageScaling)scaling {
   [_cell setImageScaling:scaling];
}

@end
