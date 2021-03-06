/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGColor.h"
#import "KGColorSpace.h"

@implementation KGColor

-initWithColorSpace:(KGColorSpace *)colorSpace pattern:(KGPattern *)pattern components:(const CGFloat *)components {
   int i;
   
   _colorSpace=[colorSpace retain];
   _pattern=[pattern retain];
   _numberOfComponents=[_colorSpace numberOfComponents]+1;
   _components=NSZoneMalloc([self zone],sizeof(CGFloat)*_numberOfComponents);
   for(i=0;i<_numberOfComponents;i++)
    _components[i]=components[i];
    
   return self;
}

-initWithColorSpace:(KGColorSpace *)colorSpace components:(const CGFloat *)components {
   int i;
   
   _colorSpace=[colorSpace retain];
   _pattern=nil;
   _numberOfComponents=[_colorSpace numberOfComponents]+1;
   _components=NSZoneMalloc([self zone],sizeof(CGFloat)*_numberOfComponents);
   for(i=0;i<_numberOfComponents;i++)
    _components[i]=components[i];
    
   return self;
}

-initWithColorSpace:(KGColorSpace *)colorSpace {
   int   i,length=[_colorSpace numberOfComponents];
   CGFloat components[length+1];
   
   for(i=0;i<length;i++)
    components[i]=0;
   components[i]=1;
   
   return [self initWithColorSpace:colorSpace components:components];
}

-initWithDeviceGray:(CGFloat)gray alpha:(CGFloat)alpha {
   CGFloat components[2]={gray,alpha};
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceGray];
   [self initWithColorSpace:colorSpace components:components];
   [colorSpace release];
   return self;
}

-initWithDeviceRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
   CGFloat components[4]={red,green,blue,alpha};
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceRGB];
   [self initWithColorSpace:colorSpace components:components];
   [colorSpace release];
   return self;
}

-initWithDeviceCyan:(CGFloat)cyan magenta:(CGFloat)magenta yellow:(CGFloat)yellow black:(CGFloat)black alpha:(CGFloat)alpha {
   CGFloat components[5]={cyan,magenta,yellow,black,alpha};
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceCMYK];
   [self initWithColorSpace:colorSpace components:components];
   [colorSpace release];
   return self;
}

-init {
   KGColorSpace *gray=[[KGColorSpace alloc] initWithDeviceGray];
   CGFloat       components[2]={0,1};
   
   [self initWithColorSpace:gray components:components];
   [gray release];
   return self;
}

-(void)dealloc {
   [_colorSpace release];
   [_pattern release];
   NSZoneFree([self zone],_components);
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-copyWithAlpha:(CGFloat)alpha {
   int   i;
   CGFloat components[_numberOfComponents];

   for(i=0;i<_numberOfComponents-1;i++)
    components[i]=_components[i];
   components[i]=alpha;
      
   return [[isa alloc] initWithColorSpace:_colorSpace components:components];
}

-(KGColorSpace *)colorSpace {
   return _colorSpace;
}

-(unsigned)numberOfComponents {
   return _numberOfComponents;
}

-(CGFloat *)components {
   return _components;
}

-(CGFloat)alpha {
   return _components[_numberOfComponents-1];
}

-(KGPattern *)pattern {
   return _pattern;
}

-(BOOL)isEqualToColor:(KGColor *)other {
   if(![_colorSpace isEqualToColorSpace:other->_colorSpace])
    return NO;

   int i;
   for(i=0;i<_numberOfComponents;i++)
    if(_components[i]!=other->_components[i])
     return NO;

   return YES;
}

-(KGColor *)convertToColorSpace:(KGColorSpace *)otherSpace {
   return nil;
}

@end
