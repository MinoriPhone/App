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

@interface StoryViewController : UIViewController <CLLocationManagerDelegate, UIWebViewDelegate>

@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIWebView *message;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) Link *currentLink;
@property NSInteger currentQueueIndex;
@property (nonatomic, retain) MediaItem *currentMediaItem;
@property (nonatomic, retain) History *history;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) IBOutlet UIButton *historyButton;
@property (nonatomic, retain) NSString *currentFilePath;
@property (nonatomic, retain) NSDate *timerStarted;
@property BOOL started;
@property NSInteger counter;
@property BOOL storyEnded;
@property BOOL storyUnzipped;

- (id)initWithStory:(Story *)newStory;
- (void)unzipStory;
- (void)showLinkQueue;
- (void)checkFile;
- (void)playMovie:(NSString *)filename;
- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification;
- (void)showImage:(NSString *)path duration:(NSInteger)duration;
- (void)hideImage;
- (void)showMessage:(NSString *)path duration:(NSInteger)duration;
- (void)hideMessage;
- (IBAction)showHistory;

@end
