#import "MediaItem.h"

@implementation MediaItem

@synthesize filename, duration, data, type;

- (id)initWithType:(MediaItemType)theType
{
    self = [super init];
    self.type = theType;
    return self;
}

@end