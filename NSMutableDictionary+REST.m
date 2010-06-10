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

// Generate HTTP post data body from the dictionary
//
// TODO: If there is at least one NSData object in the dictionary tree, the post data will be
// generated with multipart/form-data encoding type instead of the standard
// application/x-www-form-urlencoded
//
// Returns: HTTP post data
- (NSString *) HTTPPostData {
  NSMutableArray *lines = [NSMutableArray array];
  for (NSArray *pair in [self HTTPPostDataArray])
    [lines addObject: [pair componentsJoinedByString: @"="]];
  return [lines componentsJoinedByString: @"&"];
}

// HTTP post data lines
//
// Returns: HTTP post data key-value pairs, keys are already []'ed
- (NSMutableArray *) HTTPPostDataArray {
  
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
        
        // We can be at root (key without []'thingys) only in the dictionary
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
      NSString *escaped = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                              (CFStringRef)[NSString stringWithFormat: @"%@", object],
                                                                              NULL,
                                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                              kCFStringEncodingUTF8);
      [flattened insertObject: [NSArray arrayWithObjects:
                                [path componentsJoinedByString: @""],
                                escaped,
                                nil]
                      atIndex: 0];
    }
  }
  return flattened;
}

@end
