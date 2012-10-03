//
//  Story.h
//  iStory
//
//  Created by Gido Manders on 05-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Story : NSObject

@property (nonatomic, retain) NSString *zipFilename;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *imageName;
@property (nonatomic, retain) NSMutableArray *routes;

@end
