#import "KGShading+PDF.h"
#import "KGPDFDictionary.h"
#import "KGPDFArray.h"
#import "KGPDFContext.h"
#import "KGFunction+PDF.h"
#import "KGColorSpace+PDF.h"

@implementation KGShading(PDF)

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context {
   KGPDFDictionary *result=[KGPDFDictionary pdfDictionary];
   int              type;
   float            coords[6];
   int              coordsCount;
   
   if([self isAxial]){
    type=2;
    coords[0]=_startPoint.x;
    coords[1]=_startPoint.y;
    coords[2]=_endPoint.x;
    coords[3]=_endPoint.y;
    coordsCount=4;
   }
   else {
    type=3;
    coords[0]=_startPoint.x;
    coords[1]=_startPoint.y;
    coords[2]=_startRadius;
    coords[3]=_endPoint.x;
    coords[4]=_endPoint.y;
    coords[5]=_endRadius;
    coordsCount=6;
   }
   [result setIntegerForKey:"ShadingType" value:type];
   [result setObjectForKey:"ColorSpace" value:[_colorSpace encodeReferenceWithContext:context]];

   [result setObjectForKey:"Coords" value:[KGPDFArray pdfArrayWithNumbers:coords count:coordsCount]];

   [result setObjectForKey:"Domain" value:[KGPDFArray pdfArrayWithNumbers:_domain count:2]];
   [result setObjectForKey:"Function" value:[_function encodeReferenceWithContext:context]];
   KGPDFArray *extend=[KGPDFArray pdfArray];
   
   [extend addBoolean:_extendStart];
   [extend addBoolean:_extendEnd];
   [result setObjectForKey:"Extend" value:extend];

   return [context encodeIndirectPDFObject:result];
}

KGShading *axialShading(KGPDFDictionary *dictionary,KGColorSpace *colorSpace){
   KGPDFArray *coordsArray;
   KGPDFArray *domainArray;
   float       domain[2]={0,1};
   KGPDFDictionary *fnDictionary;
   KGPDFArray *extendArray;
   CGPoint     start;
   CGPoint     end;
   KGFunction *function;
   KGPDFBoolean extendStart=NO;
   KGPDFBoolean extendEnd=NO;
   
//NSLog(@"axialShading=%@",dictionary);

   if(![dictionary getArrayForKey:"Coords" value:&coordsArray]){
    NSLog(@"No Coords entry in axial shader");
    return NULL;
   }
   else {    
    if(![coordsArray getNumberAtIndex:0 value:&start.x]){
     NSLog(@"No real at Coords[0]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:1 value:&start.y]){
     NSLog(@"No real at Coords[1]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:2 value:&end.x]){
     NSLog(@"No real at Coords[2]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:3 value:&end.y]){
     NSLog(@"No real at Coords[3]");
     return NULL;
    }
   }
   
   if(![dictionary getArrayForKey:"Domain" value:&domainArray])
    domainArray=nil;
   else {
    if(![domainArray getNumberAtIndex:0 value:&(domain[0])]){
     NSLog(@"No real at Domain[0]");
     return NULL;
    }
    if(![domainArray getNumberAtIndex:1 value:&(domain[1])]){
     NSLog(@"No real at Domain[1]");
     return NULL;
    }
   }

   if(![dictionary getDictionaryForKey:"Function" value:&fnDictionary]){
    NSLog(@"No Function entry in axial shader");
    return NULL;
   }
   if((function=[KGFunction pdfFunctionWithDictionary:fnDictionary])==NULL)
    return NULL;
    
   if([dictionary getArrayForKey:"Extend" value:&extendArray]){
    if(![extendArray getBooleanAtIndex:0 value:&extendStart]){
     NSLog(@"Extend dictionary missing boolean at 0");
     return NULL;
    }
    if(![extendArray getBooleanAtIndex:1 value:&extendEnd]){
     NSLog(@"Extend dictionary missing boolean at 1");
     return NULL;
    }
   }
   
   return [[KGShading alloc] initWithColorSpace:colorSpace startPoint:start endPoint:end function:function extendStart:extendStart extendEnd:extendEnd domain:domain];    
}

KGShading *radialShading(KGPDFDictionary *dictionary,KGColorSpace *colorSpace){
   KGPDFArray *coordsArray;
   KGPDFArray *domainArray;
   float       domain[2]={0,1};
   KGPDFDictionary *fnDictionary;
   KGPDFArray *extendArray;
   CGPoint     start;
   KGPDFReal    startRadius;
   CGPoint     end;
   KGPDFReal    endRadius;
   KGFunction *function;
   KGPDFBoolean extendStart=NO;
   KGPDFBoolean extendEnd=NO;
   
//NSLog(@"axialShading=%@",dictionary);

   if(![dictionary getArrayForKey:"Coords" value:&coordsArray]){
    NSLog(@"No Coords entry in radial shader");
    return NULL;
   }
   else {    
    if(![coordsArray getNumberAtIndex:0 value:&start.x]){
     NSLog(@"No real at Coords[0]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:1 value:&start.y]){
     NSLog(@"No real at Coords[1]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:2 value:&startRadius]){
     NSLog(@"No real at Coords[2]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:3 value:&end.x]){
     NSLog(@"No real at Coords[3]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:4 value:&end.y]){
     NSLog(@"No real at Coords[4]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:5 value:&endRadius]){
     NSLog(@"No real at Coords[5]");
     return NULL;
    }
   }
   
   if(![dictionary getArrayForKey:"Domain" value:&domainArray])
    domainArray=nil;
   else {
    if(![domainArray getNumberAtIndex:0 value:&(domain[0])]){
     NSLog(@"No real at Domain[0]");
     return NULL;
    }
    if(![domainArray getNumberAtIndex:1 value:&(domain[1])]){
     NSLog(@"No real at Domain[1]");
     return NULL;
    }
   }

   if(![dictionary getDictionaryForKey:"Function" value:&fnDictionary]){
    NSLog(@"No Function entry in radial shader");
    return NULL;
   }
   if((function=[KGFunction pdfFunctionWithDictionary:fnDictionary])==NULL)
    return NULL;
    
   if([dictionary getArrayForKey:"Extend" value:&extendArray]){
    if(![extendArray getBooleanAtIndex:0 value:&extendStart]){
     NSLog(@"Extend dictionary missing boolean at 0");
     return NULL;
    }
    if(![extendArray getBooleanAtIndex:1 value:&extendEnd]){
     NSLog(@"Extend dictionary missing boolean at 1");
     return NULL;
    }
   }
   
   return [[KGShading alloc] initWithColorSpace:colorSpace startPoint:start startRadius:startRadius endPoint:end endRadius:endRadius function:function extendStart:extendStart extendEnd:extendEnd domain:domain];        
}

+(KGShading *)shadingWithPDFObject:(KGPDFObject *)object {
   KGPDFDictionary *dictionary;
   KGShading       *result=nil;
   KGPDFObject     *colorSpaceObject;
   KGColorSpace    *colorSpace;
   KGPDFInteger     shadingType;
   
   if(![object checkForType:kKGPDFObjectTypeDictionary value:&dictionary])
    return nil;
   
  // NSLog(@"sh=%@",dictionary);
   if(![dictionary getIntegerForKey:"ShadingType" value:&shadingType]){
    NSLog(@"required ShadingType missing");
    return nil;
   }
   if(![dictionary getObjectForKey:"ColorSpace" value:&colorSpaceObject]){
    NSLog(@"required ColorSpace missing");
    return nil;
   }
   if((colorSpace=[KGColorSpace colorSpaceFromPDFObject:colorSpaceObject])==nil)
    return nil;
    
   switch(shadingType){
    case 1: // Function-base shading
     NSLog(@"Unsupported shading type %d",shadingType);
     break;
    case 2: // Axial shading
     result=axialShading(dictionary,colorSpace);
     break;
    case 3: // Radial shading
     result=radialShading(dictionary,colorSpace);
     break;
    case 4: // Free-form Gouraud-shaded triangle mesh
     NSLog(@"Unsupported shading type %d",shadingType);
     break;
    case 5: // Lattice-form Gouraud-shaded triangle mesh
     NSLog(@"Unsupported shading type %d",shadingType);
     break;
    case 6: // Coons patch mesh
     NSLog(@"Unsupported shading type %d",shadingType);
     break;
    case 7: // Tensor-product patch mesh
     NSLog(@"Unsupported shading type %d",shadingType);
     break;
    default: // unknown
     NSLog(@"Unknown shading type %d",shadingType);
     break;
   }
   
   return result;
}

@end
