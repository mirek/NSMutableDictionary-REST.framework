// © 2010 Mirek Rusin
// Released under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0

#import <Foundation/Foundation.h>
#import "NSMutableDictionary+REST.h"

@interface UserPrinter : NSObject
@end

@implementation UserPrinter

- (void) didFinishElement: (id) element withPath: (NSString *) path {
  if ([path isEqualToString: @"/users/user"]) {
    NSDictionary *user = (NSDictionary *)element;
    printf("- %s (%s)\n", [[user objectForKey: @"fullname"] UTF8String],
                          [[user objectForKey: @"username"] UTF8String]);
  }
}

@end

int main(int argc, char** argv) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *stringUrl = @"http://github.com/api/v2/xml/user/search/mirek";
  NSURL *url = [NSURL URLWithString: stringUrl];
  
  // Delegate gets objects asynchronously and the method returns synchronously
  NSDictionary *users = [NSMutableDictionary dictionaryWithRESTContentsOfURL: url
                                                                    delegate: [[UserPrinter alloc] init]];
  printf("Total users: %i\n", (int)[[users objectForKey: @"users"] count]);
  
  [pool drain];
  return 0;
}
