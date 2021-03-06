/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGPDFContext.h"
#import "KGPDFArray.h"
#import "KGPDFDictionary.h"
#import "KGPDFPage.h"
#import "KGPDFContext.h"
#import "KGPDFxref.h"
#import "KGPDFxrefEntry.h"
#import "KGPDFObject_R.h"
#import "KGPDFObject_Name.h"
#import "KGPDFStream.h"
#import "KGPDFString.h"
#import "KGShading+PDF.h"
#import "KGImage+PDF.h"
#import "KGFont+PDF.h"
#import "KGMutablePath.h"
#import "KGColor.h"
#import "KGColorSpace+PDF.h"
#import "KGGraphicsState.h"
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSPathUtilities.h>
#import "KGExceptions.h"

@implementation KGPDFContext

-initWithConsumer:(KGDataConsumer *)consumer mediaBox:(const CGRect *)mediaBox auxiliaryInfo:(NSDictionary *)auxiliaryInfo {
   [super init];
   
   _dataConsumer=[consumer retain];
   _mutableData=[[consumer mutableData] retain];
   _fontCache=[NSMutableDictionary new];
   _objectToRef=NSCreateMapTable(NSObjectMapKeyCallBacks,NSObjectMapValueCallBacks,0);
   _indirectObjects=[NSMutableArray new];
   _indirectEntries=[NSMutableArray new];
   _nextNumber=1;
   _xref=[[KGPDFxref alloc] initWithData:nil];
   [_xref setTrailer:[KGPDFDictionary pdfDictionary]];
   
   [self appendCString:"%PDF-1.3\n"];
   
   _info=[[KGPDFDictionary pdfDictionary] retain];
   [_info setObjectForKey:"Author" value:[KGPDFString pdfObjectWithString:NSFullUserName()]];
   [_info setObjectForKey:"Creator" value:[KGPDFString pdfObjectWithString:[[NSProcessInfo processInfo] processName]]];
   [_info setObjectForKey:"Producer" value:[KGPDFString pdfObjectWithCString:"THE COCOTRON http://www.cocotron.org KGPDFContext"]];
   [[_xref trailer] setObjectForKey:"Info" value:_info];
   
   _catalog=[[KGPDFDictionary pdfDictionary] retain];
   [[_xref trailer] setObjectForKey:"Root" value:_catalog];
   
   _pages=[[KGPDFDictionary pdfDictionary] retain];
   [_catalog setNameForKey:"Type" value:"Catalog"];
   [_catalog setObjectForKey:"Pages" value:_pages];
   [_pages setIntegerForKey:"Count" value:0];
   
   _kids=[[KGPDFArray pdfArray] retain];
   [_pages setNameForKey:"Type" value:"Pages"];
   [_pages setObjectForKey:"Kids" value:_kids];
   
   _page=nil;
   _categoryToNext=[NSMutableDictionary new];
   _contentStreamStack=[NSMutableArray new];
   
   NSString *title=[auxiliaryInfo objectForKey:kCGPDFContextTitle];
   
   if(title==nil)
    title=@"Untitled";
    
   [_info setObjectForKey:"Title" value:[KGPDFString pdfObjectWithString:title]];
    
   [self referenceForObject:_catalog];
   [self referenceForObject:_info];

   return self;
}

-(void)dealloc {
   [_dataConsumer release];
   [_mutableData release];
   [_fontCache release];
   NSFreeMapTable(_objectToRef);
   [_indirectObjects release];
   [_indirectEntries release];
   [_xref release];
   [_info release];
   [_catalog release];
   [_pages release];
   [_kids release];
   [_page release];
   [_categoryToNext release];
   [_textStateStack release];
   [_contentStreamStack release];
   [super dealloc];
}

-(unsigned)length {
   return [_mutableData length];
}

-(NSData *)data {
   return _mutableData;
}

-(void)appendData:(NSData *)data {
   [_mutableData appendData:data];
}

-(void)appendBytes:(const void *)ptr length:(unsigned)length {
   [_mutableData appendBytes:ptr length:length];
}

-(void)appendCString:(const char *)cString {
   [_mutableData appendBytes:cString length:strlen(cString)];
}

-(void)appendString:(NSString *)string {
   NSData *data=[string dataUsingEncoding:NSASCIIStringEncoding];
   
   [_mutableData appendData:data];
}

-(void)appendFormat:(NSString *)format,... {
   NSString *string;
   va_list   arguments;

   va_start(arguments,format);
   
   string=[[NSString alloc] initWithFormat:format arguments:arguments];
   [self appendString:string];
   [string release];

   va_end(arguments);
}

-(void)appendPDFStringWithBytes:(const void *)bytesV length:(unsigned)length mutableData:(NSMutableData *)data {
   const unsigned char *bytes=bytesV;
   BOOL hex=NO;
   int  i;
   
   for(i=0;i<length;i++)
    if(bytes[i]<' ' || bytes[i]>=127 || bytes[i]=='(' || bytes[i]==')'){
     hex=YES;
     break;
    }
   
   if(hex){
    const char *hex="0123456789ABCDEF";
    int         i,bufCount,bufSize=256;
    char        buf[bufSize];
    
    [data appendBytes:"<" length:1];
    bufCount=0;
    for(i=0;i<length;i++){
     buf[bufCount++]=hex[bytes[i]>>4];
     buf[bufCount++]=hex[bytes[i]&0xF];
     
     if(bufCount==bufSize){
      [data appendBytes:buf length:bufCount];
      bufCount=0;
     }
    }
    [data appendBytes:buf length:bufCount];
    [data appendBytes:"> " length:2];
   }
   else {
    [data appendBytes:"(" length:1];
    [data appendBytes:bytes length:length];
    [data appendBytes:") " length:2];
   }
}

-(void)appendPDFStringWithBytes:(const void *)bytes length:(unsigned)length {
   [self appendPDFStringWithBytes:bytes length:length mutableData:_mutableData];
}

-(BOOL)hasReferenceForObject:(KGPDFObject *)object {
   KGPDFObject *result=NSMapGet(_objectToRef,object);
   
   return (result==nil)?NO:YES;
}

-(KGPDFObject *)referenceForObject:(KGPDFObject *)object {
   KGPDFObject *result=NSMapGet(_objectToRef,object);
   
   if(result==nil){
    KGPDFxrefEntry *entry=[KGPDFxrefEntry xrefEntryWithPosition:0 number:_nextNumber generation:0];

    result=[KGPDFObject_R pdfObjectWithNumber:_nextNumber generation:0 xref:_xref];
    NSMapInsert(_objectToRef,object,result);
    
    [_xref addEntry:entry object:object];
    [_indirectObjects addObject:object];
    [_indirectEntries addObject:entry];

    _nextNumber++;
   }
   
   return result;
}

-(void)encodePDFObject:(KGPDFObject *)object {
   if(![object isByReference] && ![self hasReferenceForObject:object])
    [object encodeWithPDFContext:self];
   else {
    KGPDFObject *ref=[self referenceForObject:object];
    
    [ref encodeWithPDFContext:self];
   }
}

-(KGPDFObject *)encodeIndirectPDFObject:(KGPDFObject *)object {
   KGPDFObject *result=[self referenceForObject:object];
   
   
   return result;
}

-(void)contentWithString:(NSString *)string {
   NSData *data=[string dataUsingEncoding:NSASCIIStringEncoding];
   
   [[[_contentStreamStack lastObject] mutableData] appendData:data];
}

-(void)contentWithFormat:(NSString *)format,... {
   NSString *string;
   va_list   arguments;

   va_start(arguments,format);
   
   string=[[NSString alloc] initWithFormat:format arguments:arguments];
   [self contentWithString:string];
   [string release];

   va_end(arguments);
}

-(void)contentPDFStringWithBytes:(const void *)bytes length:(unsigned)length {
   [self appendPDFStringWithBytes:bytes length:length mutableData:[[_contentStreamStack lastObject] mutableData]];
}

-(KGPDFObject *)referenceForFontWithName:(NSString *)name size:(float)size {
   return [(NSDictionary *)[_fontCache objectForKey:name] objectForKey:[NSNumber numberWithFloat:size]];
}

-(void)setReference:(KGPDFObject *)reference forFontWithName:(NSString *)name size:(float)size {
   NSMutableDictionary *sizes=[_fontCache objectForKey:name];
   
   if(sizes==nil){
    sizes=[NSMutableDictionary dictionary];
    [_fontCache setObject:sizes forKey:name];
   }
   
   [sizes setObject:reference forKey:[NSNumber numberWithFloat:size]];
}

-(KGPDFObject *)nameForResource:(KGPDFObject *)pdfObject inCategory:(const char *)categoryName {
   KGPDFDictionary *resources;
   KGPDFDictionary *category;
   
   if(![_page getDictionaryForKey:"Resources" value:&resources]){
    resources=[KGPDFDictionary pdfDictionary];
    [_page setObjectForKey:"Resources" value:resources];
   }
   
   if(![resources getDictionaryForKey:categoryName value:&category]){
    category=[KGPDFDictionary pdfDictionary];
    [resources setObjectForKey:categoryName value:category];
   }
   
   NSString *key=[NSString stringWithCString:categoryName];
   NSNumber *next=[_categoryToNext objectForKey:key];
   
   next=[NSNumber numberWithInt:(next==nil)?0:[next intValue]+1];
   [_categoryToNext setObject:next forKey:key];
   
   const char *objectName=[[NSString stringWithFormat:@"%s%d",categoryName,[next intValue]] cString];
   [category setObjectForKey:objectName value:pdfObject];
   
   return [KGPDFObject_Name pdfObjectWithCString:objectName];
}

-(void)beginPath {
   if(![_path isEmpty])
    [self contentWithString:@"n "];
   [super beginPath];
}

-(void)closePath {
   [super closePath];
   [self contentWithString:@"h "];
}

-(void)moveToPoint:(float)x:(float)y {
   [super moveToPoint:x:y];
   [self contentWithFormat:@"%g %g m ",x,y];
}

-(void)addLineToPoint:(float)x:(float)y {
   [super addLineToPoint:x:y];
   [self contentWithFormat:@"%g %g l ",x,y];
}

-(void)addCurveToPoint:(float)cx1:(float)cy1:(float)cx2:(float)cy2:(float)x:(float)y {
   [super addCurveToPoint:cx1:cy1:cx2:cy2:x:y];
   [self contentWithFormat:@"%g %g %g %g %g %g c ",cx1,cy1,cx2,cy2,x,y];
}

-(void)addQuadCurveToPoint:(float)cx1:(float)cy1:(float)x:(float)y {
   [super addQuadCurveToPoint:(float)cx1:(float)cy1:(float)x:(float)y];
   [self contentWithFormat:@"%g %g %g %g v ",cx1,cy1,x,y];
}

-(void)addLinesWithPoints:(const CGPoint *)points count:(unsigned)count {
   [super addLinesWithPoints:points count:count];
   
   int i;
   
   for(i=0;i<count;i++)
    [self contentWithFormat:@"%g %g l ",points[i].x,points[i].y];
}

-(void)addRects:(const CGRect *)rects count:(unsigned)count {
   [super addRects:rects count:count];
   
   int i;
   
   for(i=0;i<count;i++)
    [self contentWithFormat:@"%g %g %g %g re ",rects[i].origin.x,rects[i].origin.y,rects[i].size.width,rects[i].size.height];
}

-(void)_pathContentFromOperator:(int)start {
   int                  i,numberOfElements=[_path numberOfElements];
   const unsigned char *elements=[_path elements];
   const CGPoint       *points=[_path points];
   int                  pi=0;
   CGAffineTransform    invertUserSpaceTransform=CGAffineTransformInvert([[self currentState] userSpaceTransform]);
   
   for(i=0;i<numberOfElements;i++){
    switch(elements[i]){
    
     case kCGPathElementMoveToPoint:{
       CGPoint point=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);
       
       if(i>=start)
        [self contentWithFormat:@"%g %g m ",point.x,point.y];
      }
      break;
      
     case kCGPathElementAddLineToPoint:{
       CGPoint point=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);

       if(i>=start)
        [self contentWithFormat:@"%g %g l ",point.x,point.y];
      }
      break;

     case kCGPathElementAddCurveToPoint:{
       CGPoint c1=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);
       CGPoint c2=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);
       CGPoint end=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);

       if(i>=start)
        [self contentWithFormat:@"%g %g %g %g %g %g c ",c1.x,c1.y,c2.x,c2.y,end.x,end.y];
      }
      break;
      
     case kCGPathElementCloseSubpath:
      [self contentWithString:@"h "];
      break;
      
     case kCGPathElementAddQuadCurveToPoint:{
       CGPoint c1=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);
       CGPoint end=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);

       if(i>=start)
        [self contentWithFormat:@"%g %g %g %g v ",c1.x,c1.y,end.x,end.y];
      }
      break;
    }
   }
   
}

-(void)addArc:(float)x:(float)y:(float)radius:(float)startRadian:(float)endRadian:(int)clockwise {
   int start=[_path numberOfElements];
   
   [super addArc:x:y:radius:startRadian:endRadian:clockwise];
   [self _pathContentFromOperator:start];
}

-(void)addArcToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)radius {
   int start=[_path numberOfElements];
   [super addArcToPoint:x1:y1:x2:y2:radius];
   [self _pathContentFromOperator:start];
}

-(void)addEllipseInRect:(CGRect)rect {
   int start=[_path numberOfElements];
   [super addEllipseInRect:rect];
   [self _pathContentFromOperator:start];
}

-(void)addPath:(KGPath *)path {
   int start=[_path numberOfElements];
   [super addPath:path];
   [self _pathContentFromOperator:start];
   
}

-(void)saveGState {
   [super saveGState];
   [self contentWithString:@"q "];
}

-(void)restoreGState {
   [super restoreGState];
   [self contentWithString:@"Q "];
}

-(void)setCTM:(CGAffineTransform)matrix {
   [super setCTM:matrix];
   KGUnimplementedMethod();
}

-(void)concatCTM:(CGAffineTransform)matrix {
   [super concatCTM:matrix];
   [self contentWithFormat:@"%g %g %g %g %g %g cm ",matrix.a,matrix.b,matrix.c,matrix.d,matrix.tx,matrix.ty];
}

-(void)clipToPath {
   [super clipToPath];
   [self contentWithString:@"W "];
}

-(void)evenOddClipToPath {
   [super evenOddClipToPath];
   [self contentWithString:@"W* "];
}

-(void)clipToMask:(KGImage *)image inRect:(CGRect)rect {
   KGPDFObject *pdfObject=[image encodeReferenceWithContext:self];
   KGPDFObject *name=[self nameForResource:pdfObject inCategory:"XObject"];
   
   [self contentWithString:@"q "];
   [self translateCTM:rect.origin.x:rect.origin.y];
   [self scaleCTM:rect.size.width:rect.size.height];
   [self contentWithFormat:@"%@ Do ",name];
   [self contentWithString:@"Q "];
}

-(void)clipToRects:(const CGRect *)rects count:(unsigned)count {
   [self beginPath];
   [self addRects:rects count:count];
   [self clipToPath];
}

-(void)setStrokeColor:(KGColor *)color {
   const float *components=[color components];
   
   switch([[color colorSpace] type]){
   
    case KGColorSpaceDeviceGray:
     [self contentWithFormat:@"%f G ",components[0]];
     break;
     
    case KGColorSpaceDeviceRGB:
    case KGColorSpacePlatformRGB:
     [self contentWithFormat:@"%f %f %f RG ",components[0],components[1],components[2]];
     break;
     
    case KGColorSpaceDeviceCMYK:
     [self contentWithFormat:@"%f %f %f %f K ",components[0],components[1],components[2],components[3]];
     break;
   }
}

-(void)setFillColor:(KGColor *)color {
   const float *components=[color components];
   
   switch([[color colorSpace] type]){
   
    case KGColorSpaceDeviceGray:
     [self contentWithFormat:@"%f g ",components[0]];
     break;
     
    case KGColorSpaceDeviceRGB:
    case KGColorSpacePlatformRGB:
     [self contentWithFormat:@"%f %f %f rg ",components[0],components[1],components[2]];
     break;
     
    case KGColorSpaceDeviceCMYK:
     [self contentWithFormat:@"%f %f %f %f k ",components[0],components[1],components[2],components[3]];
     break;
   }
}

-(void)setPatternPhase:(CGSize)phase {
   [super setPatternPhase:phase];
}

-(void)setStrokePattern:(KGPattern *)pattern components:(const float *)components {
   [super setStrokePattern:pattern components:components];
}

-(void)setFillPattern:(KGPattern *)pattern components:(const float *)components {
   [super setFillPattern:pattern components:components];
}

-(void)setCharacterSpacing:(float)spacing {
   [super setCharacterSpacing:spacing];
   [self contentWithFormat:@"%g Tc ",spacing];
}

-(void)setTextDrawingMode:(int)textMode {
   [super setTextDrawingMode:textMode];   
}

-(void)setLineWidth:(float)width {
   [super setLineWidth:width];
   [self contentWithFormat:@"%g w ",width];
}

-(void)setLineCap:(int)lineCap {
   [super setLineCap:lineCap];
   [self contentWithFormat:@"%d J ",lineCap];
}

-(void)setLineJoin:(int)lineJoin {
   [super setLineJoin:lineJoin];
   [self contentWithFormat:@"%d j ",lineJoin];
}

-(void)setMiterLimit:(float)limit {
   [super setMiterLimit:limit];
   [self contentWithFormat:@"%g M ",limit];
}

-(void)setLineDashPhase:(float)phase lengths:(const float *)lengths count:(unsigned)count {
   [super setLineDashPhase:phase lengths:lengths count:count];
   
   KGPDFArray *array=[KGPDFArray pdfArray];
   int         i;
   
   for(i=0;i<count;i++)
    [array addNumber:lengths[i]];
   
   [self contentWithFormat:@"%@ %g d ",array,phase];
}

-(void)setRenderingIntent:(CGColorRenderingIntent)intent {
   [super setRenderingIntent:intent];
   
   const char *name;
   
   switch(intent){
   
    case kCGRenderingIntentAbsoluteColorimetric:
     name="AbsoluteColorimetric";
     break;
     
    default:
    case kCGRenderingIntentRelativeColorimetric:
     name="RelativeColorimetric";
     break;

    case kCGRenderingIntentSaturation:
     name="Saturation";
     break;
     
    case kCGRenderingIntentPerceptual:
     name="Perceptual";
     break;
   }
   [self contentWithFormat:@"/%s ri ",name];
}

-(void)setBlendMode:(int)mode {
   [super setBlendMode:mode];
   
}

-(void)setFlatness:(float)flatness {
   [super setFlatness:flatness];
   
   [self contentWithFormat:@"%g i ",flatness];
}

-(void)setInterpolationQuality:(CGInterpolationQuality)quality {
   [super setInterpolationQuality:quality];
}

-(void)setShadowOffset:(CGSize)offset blur:(float)blur color:(KGColor *)color {
   [super setShadowOffset:offset blur:blur color:color];
   
}

-(void)setShadowOffset:(CGSize)offset blur:(float)blur {
   [super setShadowOffset:offset blur:blur];
   
}

-(void)setShouldAntialias:(BOOL)yesOrNo {
   [super setShouldAntialias:yesOrNo];
   
}

-(void)drawPath:(CGPathDrawingMode)pathMode {
   switch(pathMode){
   
    case kCGPathFill:
     [self contentWithString:@"f "];
     break;
     
    case kCGPathEOFill:
     [self contentWithString:@"f* "];
     break;
     
    case kCGPathStroke:
     [self contentWithString:@"S "];
     break;

    case kCGPathFillStroke:
     [self contentWithString:@"B "];
     break;

    case kCGPathEOFillStroke:
     [self contentWithString:@"B* "];
     break;
         
   }
   [_path reset];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
    unsigned char bytes[count];

   [[[self currentState] font] getMacRomanBytes:bytes forGlyphs:glyphs length:count];
   [self showText:bytes length:count];
}

-(void)showText:(const char *)text length:(unsigned)length {
   [self contentWithString:@"BT "];
   
   KGGraphicsState *state=[self currentState];
   KGPDFObject *pdfObject=[[state font] encodeReferenceWithContext:self size:[state pointSize]];
   KGPDFObject *name=[self nameForResource:pdfObject inCategory:"Font"];

   [self contentWithFormat:@"%@ %g Tf ",name,[[self currentState] pointSize]];

   CGAffineTransform matrix=[self textMatrix];
   [self contentWithFormat:@"%g %g %g %g %g %g Tm ",matrix.a,matrix.b,matrix.c,matrix.d,matrix.tx,matrix.ty];
   
   [self contentPDFStringWithBytes:text length:length];
   [self contentWithString:@" Tj "];
   
   [self contentWithString:@"ET "];
}

-(void)drawShading:(KGShading *)shading {
   KGPDFObject *pdfObject=[shading encodeReferenceWithContext:self];
   KGPDFObject *name=[self nameForResource:pdfObject inCategory:"Shading"];
    
   [self contentWithFormat:@"%@ sh ",name];
}

-(void)drawImage:(KGImage *)image inRect:(CGRect)rect {
   KGPDFObject *pdfObject=[image encodeReferenceWithContext:self];
   KGPDFObject *name=[self nameForResource:pdfObject inCategory:"XObject"];
   
   [self contentWithString:@"q "];
   [self translateCTM:rect.origin.x:rect.origin.y];
   [self scaleCTM:rect.size.width:rect.size.height];
   [self contentWithFormat:@"%@ Do ",name];
   [self contentWithString:@"Q "];
}

-(void)drawLayer:(KGLayer *)layer inRect:(CGRect)rect {
}

-(void)beginPage:(const CGRect *)mediaBox {
   KGPDFObject *stream;
   
   _page=[[KGPDFDictionary pdfDictionary] retain];
   
   [_page setNameForKey:"Type" value:"Page"];
   [_page setObjectForKey:"MediaBox" value:[KGPDFArray pdfArrayWithRect:*mediaBox]];

   stream=[KGPDFStream pdfStream];
   [_page setObjectForKey:"Contents" value:stream];
   [_contentStreamStack addObject:stream];
   
   [_page setObjectForKey:"Parent" value:[self referenceForObject:_pages]];
   
   [self referenceForObject:_page];
}

-(void)internIndirectObjects {
   int i;

   for(i=0;i<[_indirectObjects count];i++){ // do not cache 'count', can grow during encoding
    KGPDFxrefEntry *entry=[_indirectEntries objectAtIndex:i];
    KGPDFObject    *object=[_indirectObjects objectAtIndex:i];
    unsigned        position=[_mutableData length];
    
    [entry setPosition:position];
    [self appendFormat:@"%d %d obj\n",[entry number],[entry generation]];
    [object encodeWithPDFContext:self];
    [self appendFormat:@"endobj\n"];
   }
   [_indirectObjects removeAllObjects];
   [_indirectEntries removeAllObjects];
}

-(void)endPage {
   KGPDFInteger pageCount=0;
   
   [_contentStreamStack removeLastObject];
      
   [_kids addObject:_page];
   
   [_pages getIntegerForKey:"Count" value:&pageCount];
   pageCount++;
   [_pages setIntegerForKey:"Count" value:pageCount];
   
   [_page release];
   _page=nil;
   
   // Do not invoke [self internIndirectObjects], it's too early: do it only after -endPrinting,
   // else subsequent pages are not saved, because the 'Kids' array has already been encoded!
}

-(void)close {
   [self internIndirectObjects];
   [self encodePDFObject:(id)_xref];
}

-(void)deviceClipReset {
}

@end
