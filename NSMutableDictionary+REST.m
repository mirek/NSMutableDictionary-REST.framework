
#import "NSMutableDictionary+REST.h"

@implementation NSMutableDictionary (REST)

+ (NSMutableDictionary *) dictionaryWithRESTContentsOfURL: (NSURL *) url {
  NSMutableDictionaryRESTParser *parser = [[NSMutableDictionaryRESTParser alloc] init];
  [parser parseWithURL: url];
  return parser.tree;
}

@end
