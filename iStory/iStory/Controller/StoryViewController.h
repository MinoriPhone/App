//
//  ViewController.h
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <CoreLocation/CoreLocation.h>

@class Location, Story, Link, Node, History;

@interface StoryViewController : UIViewController {
    MPMoviePlayerController *moviePlayer;
    UIImageView *imageView;
    UITextView *message;
    CLLocationManager *locationManager;
    Story *story;
    Link *currentLink;
    NSInteger currentQueueIndex;
    History *history;
    NSTimer *timer;
}

@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UITextView *message;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) Link *currentLink;
@property NSInteger currentQueueIndex;
@property (nonatomic, retain) History *history;
@property (nonatomic, retain) NSTimer *timer;

- (void)showLinkQueue;
- (void)playMovie:(NSString *)filename;
- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification;
- (void)showImage:(NSString *)filename duration:(NSInteger)duration;
- (void)hideImage;
- (void)showMessage:(NSString *)filename duration:(NSInteger)duration;
- (void)hideMessage;
- (CLLocationDistance)calculateDistance:(Node *)node;
- (void)checkStart;

@end
