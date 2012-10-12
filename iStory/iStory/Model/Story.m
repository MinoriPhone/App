#import "Story.h"

@implementation Story

@synthesize zipFilename, name, image, routes;

- (NSString *)dir
{
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:self.name];
}

@end