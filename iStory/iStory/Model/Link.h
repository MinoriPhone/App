//
//  Link.h
//  iStory
//
//  Created by Gido Manders on 05-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

@class Node;

@interface Link : NSObject

@property (nonatomic, retain) NSNumber *identifier;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) Node *from;
@property (nonatomic, retain) Node *to;
@property (nonatomic, retain) NSMutableArray *next;
@property (nonatomic, retain) NSMutableArray *queue;

@end
