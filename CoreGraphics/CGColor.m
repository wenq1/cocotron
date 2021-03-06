/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <CoreGraphics/CGColor.h>
#import "KGColor.h"
#import "KGColorSpace.h"

CGColorRef CGColorRetain(CGColorRef self) {
   return [self retain];
}

void       CGColorRelease(CGColorRef self) {
   [self release];
}

CGColorRef CGColorCreate(CGColorSpaceRef colorSpace,const CGFloat *components) {
   return [[KGColor alloc] initWithColorSpace:colorSpace components:components];
}

CGColorRef CGColorCreateGenericGray(CGFloat gray,CGFloat a) {
   return [[KGColor alloc] initWithDeviceGray:gray alpha:a];
}

CGColorRef CGColorCreateGenericRGB(CGFloat r,CGFloat g,CGFloat b,CGFloat a) {
   return [[KGColor alloc] initWithDeviceRed:r green:g blue:b alpha:a];
}

CGColorRef CGColorCreateGenericCMYK(CGFloat c,CGFloat m,CGFloat y,CGFloat k,CGFloat a) {
   return [[KGColor alloc] initWithDeviceCyan:c magenta:m yellow:y black:k alpha:a];
}

CGColorRef CGColorCreateWithPattern(CGColorSpaceRef colorSpace,CGPatternRef pattern,const CGFloat *components) {
   return [[KGColor alloc] initWithColorSpace:colorSpace pattern:pattern components:components];
}

CGColorRef CGColorCreateCopy(CGColorRef self) {
   return [self copy];
}

CGColorRef CGColorCreateCopyWithAlpha(CGColorRef self,CGFloat a) {
   return [self copyWithAlpha:a];
}

BOOL CGColorEqualToColor(CGColorRef self,CGColorRef other) {
   return [self isEqualToColor:other];
}

CGColorSpaceRef CGColorGetColorSpace(CGColorRef self) {
   return [self colorSpace];
}

size_t CGColorGetNumberOfComponents(CGColorRef self) {
   return [self numberOfComponents];
}

const CGFloat *CGColorGetComponents(CGColorRef self) {
   return [self components];
}

CGFloat CGColorGetAlpha(CGColorRef self) {
   return [self alpha];
}

CGPatternRef CGColorGetPattern(CGColorRef self) {
   return [self pattern];
}
