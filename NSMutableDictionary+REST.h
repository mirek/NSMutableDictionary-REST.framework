// © 2010 Mirek Rusin
// Released under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0

#import <Foundation/Foundation.h>
#import "NSMutableDictionaryRESTParser.h"

@interface NSMutableDictionary (REST)

+ (NSMutableDictionary *) dictionaryWithRESTContentsOfURL: (NSURL *) url;
+ (NSMutableDictionary *) dictionaryWithRESTContentsOfURL: (NSURL *) url delegate: (id) delegate;
- (NSString *) HTTPPostData;
- (NSMutableArray *) HTTPPostDataArray;

@end
