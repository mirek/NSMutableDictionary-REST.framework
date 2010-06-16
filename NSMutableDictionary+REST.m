// © 2010 Mirek Rusin
// Released under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0

#import "NSMutableDictionary+REST.h"

@implementation NSMutableDictionary (REST)

+ (NSMutableDictionary *) dictionaryWithRESTContentsOfURL: (NSURL *) url {
  NSMutableDictionaryRESTParser *parser = [[NSMutableDictionaryRESTParser alloc] init];
  [parser parseWithURL: url];
  return parser.tree;
}

+ (NSMutableDictionary *) dictionaryWithRESTContentsOfURL: (NSURL *) url delegate: (id) delegate {
  NSMutableDictionaryRESTParser *parser = [[NSMutableDictionaryRESTParser alloc] init];
  parser.delegate = delegate;
  [parser parseWithURL: url];
  return parser.tree;
}

/// Generate HTTP post data body from the dictionary
//
// Returns: HTTP post data
- (NSString *) RESTURLEncodedHTTPPostData {
  NSMutableArray *lines = [NSMutableArray array];
  for (NSArray *pair in [self RESTArrayHTTPPostData]) {
    NSMutableArray *escapedPair = [NSMutableArray arrayWithCapacity: 2];
    for (id element in pair)
      [escapedPair addObject: (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                  (CFStringRef)[NSString stringWithFormat: @"%@", element],
                                                                                  NULL,
                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                  kCFStringEncodingUTF8)];
    [lines addObject: [escapedPair componentsJoinedByString: @"="]];
  }
  return [lines componentsJoinedByString: @"&"];
}

- (NSString *) RESTMultipartHTTPPostDataWithBoundary: (NSString *) boundary {
  NSMutableArray *lines = [NSMutableArray array];
  for (NSArray *pair in [self RESTArrayHTTPPostData]) {
    [lines addObject: [NSString stringWithFormat: @"--%@", boundary]];
    [lines addObject: [NSString stringWithFormat: @"Content-Disposition: form-data; name=\"%@\"", [pair objectAtIndex: 0]]];
    [lines addObject: @""];
    [lines addObject: [NSString stringWithFormat: @"%@", [pair lastObject]]];
  }
  [lines addObject: [NSString stringWithFormat: @"--%@--", boundary]];
  NSString *r = [lines componentsJoinedByString: @"\r\n"];
  return r;
}

/// HTTP post data (flattened) lines
//
// Returns: HTTP post data key-value pairs, keys are []'ed
- (NSMutableArray *) RESTArrayHTTPPostData {
  
  // Flatten the dictionary
  NSMutableArray *flattened = [NSMutableArray array];
  NSMutableArray *objects = [NSMutableArray arrayWithObject: self];
  NSMutableArray *paths = [NSMutableArray arrayWithObject: [NSMutableArray array]];
  while ([objects count] > 0) {
    id object = [objects lastObject];
    [objects removeLastObject];
    NSMutableArray *path = [paths lastObject];
    [paths removeLastObject];
    if ([object isKindOfClass: NSClassFromString(@"NSDictionary")]) {
      for (NSString *key in [object allKeys]) {
        NSMutableArray *pathWithKey = [NSMutableArray arrayWithArray: path];
        
        // We can be at the root and we need a key without []'thingys
        if ([pathWithKey count] == 0)
          [pathWithKey addObject: [NSString stringWithFormat: @"%@", key]];
        else
          [pathWithKey addObject: [NSString stringWithFormat: @"[%@]", key]];
        [paths addObject: pathWithKey];
        [objects addObject: [object objectForKey: key]];
      }
    } else if ([object isKindOfClass: NSClassFromString(@"NSArray")]) {
      for (int i = 0; i < [object count]; i++) {
        NSMutableArray *pathWithKey = [NSMutableArray arrayWithArray: path];
        [pathWithKey addObject: [NSString stringWithFormat: @"[%i]", i]];
        [paths addObject: pathWithKey];
        [objects addObject: [object objectAtIndex: i]];
      }
    } else {
      [flattened insertObject: [NSArray arrayWithObjects:
                                [path componentsJoinedByString: @""],
                                object,
                                nil]
                      atIndex: 0];
    }
  }
  return flattened;
}

- (NSData *) postRESTWithURL: (NSString *) urlString {
  return [self sendRESTWithURL: urlString
                        method: @"POST"
                      encoding: @"multipart/form-data"
                      response: nil
                         error: nil];
}

- (NSData *) putRESTWithURL: (NSString *) urlString {
  return [self sendRESTWithURL: urlString
                        method: @"PUT"
                      encoding: @"multipart/form-data"
                      response: nil
                         error: nil];
}

- (NSData *) sendRESTWithURL: (NSString *) urlString
                      method: (NSString *) method
                    encoding: (NSString *) encoding
                    response: (NSURLResponse **) urlResponse
                       error: (NSError **) error
{
  NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: urlString] 
                                                               cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                           timeoutInterval: 60.0] autorelease];
  
  [request setHTTPMethod: method];

  if ([encoding isEqualToString: @"multipart/form-data"]) {
    
    // multipart/form-data encoding, let's get a random boundary string
    NSString *boundary = [NSString stringWithFormat:@"----boundary%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c",
                          (char)(65 + (arc4random() % 25)), (char)(65 + (arc4random() % 25)),
                          (char)(65 + (arc4random() % 25)), (char)(65 + (arc4random() % 25)),
                          (char)(65 + (arc4random() % 25)), (char)(65 + (arc4random() % 25)),
                          (char)(65 + (arc4random() % 25)), (char)(65 + (arc4random() % 25)),
                          (char)(65 + (arc4random() % 25)), (char)(65 + (arc4random() % 25)),
                          (char)(65 + (arc4random() % 25)), (char)(65 + (arc4random() % 25)),
                          (char)(65 + (arc4random() % 25)), (char)(65 + (arc4random() % 25)),
                          (char)(65 + (arc4random() % 25)), (char)(65 + (arc4random() % 25))];
    
    [request setHTTPBody: [[self RESTMultipartHTTPPostDataWithBoundary: boundary] dataUsingEncoding: NSASCIIStringEncoding]];
    [request setValue: [NSString stringWithFormat: @"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField: @"Content-Type"];
    
  } else if ([encoding isEqualToString: @"application/x-www-form-urlencoded"]) {
    
    // application/x-www-form-urlencoded encoding
    [request setHTTPBody: [[self RESTURLEncodedHTTPPostData] dataUsingEncoding: NSASCIIStringEncoding]];
    [request setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
    
  } else {
    
    // Unknown encoding type
    assert(NO);
  }

  // TODO: Async post
  // NSURLConnection *conn = [[[NSURLConnection alloc] initWithRequest: request delegate: nil] autorelease];
  // while (![conn isFinished]) {
  //   [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode 
  //                            beforeDate: [NSDate distantFuture]];
  // }
  
  return [NSURLConnection sendSynchronousRequest: request
                               returningResponse: urlResponse
                                           error: error];
}

@end
