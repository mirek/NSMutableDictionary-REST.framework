// © 2010 Mirek Rusin
// Released under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0

#import <libxml/tree.h>
#import <libxml/xmlstring.h>

typedef enum {
  NSMutableDictionaryRESTParserElementTypeNil,
  NSMutableDictionaryRESTParserElementTypeStringOrDictionary,
  NSMutableDictionaryRESTParserElementTypeArray,
  NSMutableDictionaryRESTParserElementTypeFloat,
  NSMutableDictionaryRESTParserElementTypeInteger
} NSMutableDictionaryRESTParserElementType;

@interface NSMutableDictionaryRESTParser : NSObject {

@private
  
  xmlParserCtxtPtr context;
  
  NSURLConnection *urlConnection;

  BOOL processing;

  NSAutoreleasePool *pool;

  NSMutableArray *stack;
  NSMutableArray *typeStack;
  NSMutableArray *nameStack;
  NSMutableData *data;
  
  id delegate;
}

@property (nonatomic, retain) NSMutableDictionary *tree;

@property (nonatomic, retain) NSMutableArray *stack;
@property (nonatomic, retain) NSMutableArray *typeStack;
@property (nonatomic, retain) NSMutableArray *nameStack;

@property (nonatomic, retain) NSMutableData *data;

@property (nonatomic, retain) id delegate;

@property BOOL processing;

@property (nonatomic, retain) NSURLConnection *urlConnection;

@property (nonatomic, assign) NSAutoreleasePool *pool;

- (void) parseWithURL: (NSURL *) url;

@end
