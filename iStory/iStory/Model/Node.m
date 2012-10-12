#import "Node.h"

@implementation Node

@synthesize longitude, latitude, radius, location;

- (id)init
{
    self = [super init];
    self.radius = [NSNumber numberWithInt:10];
    return self;
}

@end