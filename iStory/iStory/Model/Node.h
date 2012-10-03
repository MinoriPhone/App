//
//  Node.h
//  iStory
//
//  Created by Gido Manders on 05-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface Node : NSObject

@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *radius;
@property (nonatomic, retain) CLLocation *location;

@end
