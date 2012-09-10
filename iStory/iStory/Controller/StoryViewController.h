//
//  ViewController.h
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <CoreLocation/CoreLocation.h>

@class Location, Node;

@interface StoryViewController : UIViewController {
    MPMoviePlayerController *moviePlayer;
    CLLocationManager *locationManager;
    Node *node;
    NSTimer *timer;
}

@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) Node *node;
@property (nonatomic, retain) NSTimer *timer;

- (void)playMovie:(NSString *)filename;
- (BOOL)inRange;
- (void)checkLocation;

@end
