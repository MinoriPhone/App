//
//  ViewController.h
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <CoreLocation/CoreLocation.h>

@class Location, Story, Node;

@interface StoryViewController : UIViewController {
    MPMoviePlayerController *moviePlayer;
    CLLocationManager *locationManager;
    Story *story;
    NSTimer *timer;
}

@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) NSTimer *timer;

- (void)playMovie:(NSString *)filename ofType:(NSString *)type;
- (CLLocationDistance)calculateDistance:(Node *)node;
- (void)checkStart;
<<<<<<< HEAD
=======
- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification;
>>>>>>> movie

@end
