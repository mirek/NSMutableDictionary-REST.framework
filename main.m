// © 2010 Mirek Rusin
// Released under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0

#import <Foundation/Foundation.h>
#import "NSMutableDictionary+REST.h"

int main(int argc, char** argv) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *stringUrl = @"http://github.com/api/v2/xml/user/search/mirek";
  NSURL *url = [NSURL URLWithString: stringUrl];
  NSLog(@"%@", [NSMutableDictionary dictionaryWithRESTContentsOfURL: url]);
  
  [pool drain];
  return 0;
}
