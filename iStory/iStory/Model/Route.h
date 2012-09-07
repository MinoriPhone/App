//
//  Route.h
//  iStory
//
//  Created by Gido Manders on 05-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

@class Link;

@interface Route : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) Link *start;

@end
