//
//  ViewController.h
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <CoreLocation/CoreLocation.h>
#import "HistoryViewController.h"

@class Location, Story, Link, Node, History, MediaItem;

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
    NSString *currentVideoFilePath;
    NSDate *timerStarted;
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
@property (nonatomic, retain) IBOutlet UIBarButtonItem *historyButton;
@property (nonatomic, retain) NSString *currentVideoFilePath;
@property (nonatomic, retain) NSDate *timerStarted;

- (void)showLinkQueue;
- (void)readFileForMediaItem:(MediaItem *)mediaItem;
- (void)playMovie:(NSString *)filename;
- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification;
- (void)showImage:(NSData *)data duration:(NSInteger)duration;
- (void)hideImage;
- (void)showMessage:(NSData *)data duration:(NSInteger)duration;
- (void)hideMessage;
- (CLLocationDistance)calculateDistance:(Node *)node;
- (void)checkStart;

@end
