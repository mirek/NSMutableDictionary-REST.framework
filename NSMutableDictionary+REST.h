
#import <Foundation/Foundation.h>
#import "NSMutableDictionaryRESTParser.h"

@interface NSMutableDictionary (REST)

+ (NSMutableDictionary *) dictionaryWithRESTContentsOfURL: (NSURL *) url;

@end
