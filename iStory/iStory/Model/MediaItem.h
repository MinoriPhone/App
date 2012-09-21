//
//  MediaItem.h
//  iStory
//
//  Created by Gido Manders on 13-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MediaItem : NSObject

@property (nonatomic, retain) NSString *filename;
@property NSInteger duration;
@property (nonatomic, retain) NSData *data;

@end
