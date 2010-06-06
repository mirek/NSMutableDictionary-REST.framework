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

@end
