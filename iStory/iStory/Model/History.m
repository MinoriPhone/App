//
//  History.m
//  iStory
//
//  Created by Gido Manders on 13-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

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
