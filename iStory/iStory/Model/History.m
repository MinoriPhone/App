#import "History.h"

@implementation History

@synthesize linkQueue;

- (id)init
{
    self = [super init];
    self.linkQueue = [[NSMutableArray alloc] init];
    return self;
}

@end