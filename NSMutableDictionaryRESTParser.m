
#import "NSMutableDictionaryRESTParser.h"

// Declaration for SAX callbacks and structure
static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void	charactersFoundSAX(void * ctx, const xmlChar * ch, int len);
static void errorEncounteredSAX(void * ctx, const char * msg, ...);
static xmlSAXHandler simpleSAXHandlerStruct;

@implementation NSMutableDictionaryRESTParser

@synthesize tree;
@synthesize stack;
@synthesize typeStack;
@synthesize nameStack;
@synthesize data;

@synthesize delegate;
@synthesize urlConnection;
@synthesize processing;
@synthesize pool;

- (void) parseWithURL: (NSURL *) url {
  self.pool = [[NSAutoreleasePool alloc] init];

  self.processing = YES;

  self.tree = [NSMutableDictionary dictionary];
  self.stack = [NSMutableArray arrayWithObject: self.tree];
  self.typeStack = [NSMutableArray arrayWithObject: [NSNumber numberWithInt: NSMutableDictionaryRESTParserElementTypeStringOrDictionary]];
  self.nameStack = [NSMutableArray arrayWithObject: @"root"];

  [[NSURLCache sharedURLCache] removeAllCachedResponses];
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL: url];
  urlConnection = [[NSURLConnection alloc] initWithRequest: urlRequest delegate: self];
  context = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, self, NULL, 0, NULL);

  // [self performSelectorOnMainThread: @selector(downloadStarted) withObject: nil waitUntilDone: NO];

  if (urlConnection != nil) {
    do {
      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    } while (processing);
  }

  // Release resources used only in this thread
  xmlFreeParserCtxt(context);

  self.urlConnection = nil;

  [pool drain];
  self.pool = nil;
}

#pragma mark NSURLConnection delegate methods

// Disable caching
- (NSCachedURLResponse *) connection: (NSURLConnection *) connection willCacheResponse: (NSCachedURLResponse *) cachedResponse {
  return nil;
}

// Forward errors to the delegate
- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error {
  self.processing = NO;
  [self performSelectorOnMainThread: @selector(parseError:) withObject: error waitUntilDone: NO];
}

- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) receivedData {
  xmlParseChunk(context, (const char *)[receivedData bytes], [receivedData length], NO);
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection {
  xmlParseChunk(context, NULL, 0, YES);
  self.processing = NO; 
//  if ([delegate respondsToSelector: @selector(parseEnded)])
//    [delegate performSelectorOnMainThread: @selector(parseEnded) withObject: self waitUntilDone: NO];
}

@end

#pragma mark SAX Stuff

static void startElementSAX(void *ctx,
                            const xmlChar *localname,
                            const xmlChar *prefix,
                            const xmlChar *URI, 
                            int nb_namespaces,
                            const xmlChar **namespaces, 
                            int nb_attributes,
                            int nb_defaulted,
                            const xmlChar **attributes)
{
  NSMutableDictionaryRESTParser *parser = (NSMutableDictionaryRESTParser *)ctx;
  
  id new = [NSMutableDictionary dictionary];
  NSMutableDictionaryRESTParserElementType newType = NSMutableDictionaryRESTParserElementTypeStringOrDictionary;
  parser.data = [NSMutableData data];
  
  if (nb_attributes > 0) {
    int i, j;
    for (j = 0, i = 0; i < nb_attributes; i++, j += 5) {
      
      // We're interested in type attribute only
      if (!xmlStrcmp((const xmlChar *)"type", attributes[j])) {
        if (!xmlStrncmp((const xmlChar *)"array", attributes[j+3], strlen("array"))) {
          newType = NSMutableDictionaryRESTParserElementTypeArray;
          new = [NSMutableArray array];
          break;
        } else if (!xmlStrncmp((const xmlChar *)"float", attributes[j+3], strlen("float"))) {
          newType = NSMutableDictionaryRESTParserElementTypeFloat;
          break;
        }
      }
    }
  }
  
  // Push new element to the stack
  [parser.stack addObject: new];
  [parser.typeStack addObject: [NSNumber numberWithInt: newType]];
  [parser.nameStack addObject: [NSString stringWithUTF8String: (const char *)localname]];
}

static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {    
  NSMutableDictionaryRESTParser *parser = (NSMutableDictionaryRESTParser *)ctx;
  
  // Let's get the current element
  id last = [parser.stack lastObject];
  NSMutableDictionaryRESTParserElementType lastType = (NSMutableDictionaryRESTParserElementType)[[parser.typeStack lastObject] intValue];
  NSString *lastName = [parser.nameStack lastObject];
  
  // ...and remove it from the stack
  [parser.stack removeLastObject];
  [parser.typeStack removeLastObject];
  [parser.nameStack removeLastObject];

  // Current string value
  NSString *string = [[NSString alloc] initWithData: parser.data encoding: NSUTF8StringEncoding];

  // Depending on the type we can mutate to the proper class
  id new;
  switch (lastType) {
    case NSMutableDictionaryRESTParserElementTypeArray:
      new = last;
      break;

    case NSMutableDictionaryRESTParserElementTypeFloat:
      new = [NSNumber numberWithFloat: [string floatValue]];
      break;
      
    case NSMutableDictionaryRESTParserElementTypeStringOrDictionary:
      if ([last count] > 0)
        new = last;
      else
        new = string;
      break;
  }
  
  // We'll need current element's parent to assign new (mutated or not) element
  id parent = [parser.stack lastObject];
  NSMutableDictionaryRESTParserElementType parentType = (NSMutableDictionaryRESTParserElementType)[[parser.typeStack lastObject] intValue];
  
  // Parent had to be one of container types
  switch (parentType) {
    case NSMutableDictionaryRESTParserElementTypeArray: [parent addObject: new]; break;
    case NSMutableDictionaryRESTParserElementTypeStringOrDictionary: [parent setObject: new forKey: lastName]; break;
  }
}

static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len) {
  NSMutableDictionaryRESTParser *parser = (NSMutableDictionaryRESTParser *)ctx;
  [parser.data appendBytes: ch length: len];
}

static void errorEncounteredSAX(void *ctx, const char *msg, ...) {
  NSCAssert(NO, @"Unhandled error encountered during SAX parse.");
}

static xmlSAXHandler simpleSAXHandlerStruct = {
  NULL,                // internalSubset
  NULL,                // isStandalone
  NULL,                // hasInternalSubset
  NULL,                // hasExternalSubset
  NULL,                // resolveEntity
  NULL,                // getEntity
  NULL,                // entityDecl
  NULL,                // notationDecl
  NULL,                // attributeDecl
  NULL,                // elementDecl
  NULL,                // unparsedEntityDecl
  NULL,                // setDocumentLocator
  NULL,                // startDocument
  NULL,                // endDocument
  NULL,                // startElement*/
  NULL,                // endElement
  NULL,                // reference
  charactersFoundSAX,  // characters
  NULL,                // ignorableWhitespace
  NULL,                // processingInstruction
  NULL,                // comment
  NULL,                // warning
  errorEncounteredSAX, // error
  NULL,                // fatalError //: unused error() get all the errors
  NULL,                // getParameterEntity
  NULL,                // cdataBlock
  NULL,                // externalSubset
  XML_SAX2_MAGIC,      //
  NULL,                //
  startElementSAX,     // startElementNs
  endElementSAX,       // endElementNs
  NULL,                // serror
};
