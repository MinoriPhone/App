//
//  Node.m
//  iStory
//
//  Created by Gido Manders on 05-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import "Node.h"

@implementation Node

@synthesize longitude, latitude, radius;

- (id)init
{
    self = [super init];
    self.radius = [NSNumber numberWithInt:2];
    return self;
}

@end
